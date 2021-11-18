//
//  ObjectsModelDataHandler.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/11/21.
//

import CoreImage
import TensorFlowLite
import UIKit
import Accelerate

/// Stores one formatted inference.
struct Inference {
    let confidence: Float
    let className: String
    let rect: CGRect
    let displayColor: UIColor
}

/// This class handles all data preprocessing and makes calls to run inference on a given frame
/// by invoking the `Interpreter`. It then formats the inferences obtained and returns the top N
/// results for a successful inference.
class ObjectsModelDataHandler: NSObject {

    // MARK: - Internal Properties
    /// The current thread count used by the TensorFlow Lite Interpreter.
    let threadCount: Int
    let threadCountLimit = 10

    let threshold: Float = 0.5

    // MARK: Model parameters
    let batchSize = 1
    let inputChannels = 3
    let inputWidth = 320
    let inputHeight = 320

    // image mean and std for floating model, should be consistent with parameters used in model training
    let imageMean: Float = 127.5
    let imageStd:  Float = 127.5

    // MARK: Private properties
    private var labels: [String] = []

    /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
    private var interpreter: Interpreter

    private let bgraPixel = (channels: 4, alphaComponent: 3, lastBgrComponent: 2)
    private let rgbPixelChannels = 3
    private let colorStrideValue = 10
    private let colors = [
        UIColor.red,
        UIColor(displayP3Red: 90.0/255.0, green: 200.0/255.0, blue: 250.0/255.0, alpha: 1.0),
        UIColor.green,
        UIColor.orange,
        UIColor.blue,
        UIColor.purple,
        UIColor.magenta,
        UIColor.yellow,
        UIColor.cyan,
        UIColor.brown
    ]

    // MARK: - Initialization

    /// A failable initializer for `ModelDataHandler`. A new instance is created if the model and
    /// labels files are successfully loaded from the app's main bundle. Default `threadCount` is 1.
    init?(modelFileInfo: FileInfo, labelsFileInfo: FileInfo, threadCount: Int = 4) {
        let modelFilename = modelFileInfo.name
        guard let modelPath = Bundle.main.path(forResource: modelFilename, ofType: modelFileInfo.extension ) else {
            fatalError("Failed to load the model file with name: \(modelFilename).\(modelFileInfo.extension)")
        }

        // Specify the options for the `Interpreter`.
        self.threadCount = threadCount
        var options = Interpreter.Options()
        options.threadCount = threadCount
        do {
            // Create the `Interpreter`.
            self.interpreter = try Interpreter(modelPath: modelPath, options: options)
            // Allocate memory for the model's input `Tensor`s.
            try self.interpreter.allocateTensors()
        } catch let error {
            fatalError("Failed to create the interpreter with error: \(error.localizedDescription)")
        }

        super.init()

        // Load the classes listed in the labels file.
        self.loadLabels(fileInfo: labelsFileInfo)
    }

    /// This class handles all data preprocessing and makes calls to run inference on a given frame
    /// through the `Interpreter`. It then formats the inferences obtained and returns the top N
    /// results for a successful inference.
    func runModel(onFrame pixelBuffer: CVPixelBuffer) -> [Inference]? {
        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32ARGB ||
               sourcePixelFormat == kCVPixelFormatType_32BGRA ||
               sourcePixelFormat == kCVPixelFormatType_32RGBA)


        let imageChannels = 4
        assert(imageChannels >= self.inputChannels)

        // Crops the image to the biggest square in the center and scales it down to model dimensions.
        let scaledSize = CGSize(width: self.inputWidth, height: self.inputHeight)
        guard let scaledPixelBuffer = pixelBuffer.resized(to: scaledSize) else {
            return nil
        }

        let outputBoundingBox: Tensor
        let outputClasses: Tensor
        let outputScores: Tensor
        let outputCount: Tensor
        do {
            let inputTensor = try self.interpreter.input(at: 0)

            // Remove the alpha component from the image buffer to get the RGB data.
            guard let rgbData = self.rgbDataFromBuffer(scaledPixelBuffer, byteCount: self.batchSize * self.inputWidth * self.inputHeight * self.inputChannels, isModelQuantized: inputTensor.dataType == .uInt8) else {
                print("Failed to convert the image buffer to RGB data.")
                return nil
            }

            // Copy the RGB data to the input `Tensor`.
            try self.interpreter.copy(rgbData, toInputAt: 0)

            // Run inference by invoking the `Interpreter`.
            try self.interpreter.invoke()

            outputBoundingBox = try self.interpreter.output(at: 0)
            outputClasses = try self.interpreter.output(at: 1)
            outputScores = try self.interpreter.output(at: 2)
            outputCount = try self.interpreter.output(at: 3)
        } catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
            return nil
        }

        // Formats the results
        let resultArray = self.formatResults(
            boundingBox: [Float](unsafeData: outputBoundingBox.data) ?? [],
            outputClasses: [Float](unsafeData: outputClasses.data) ?? [],
            outputScores: [Float](unsafeData: outputScores.data) ?? [],
            outputCount: Int(([Float](unsafeData: outputCount.data) ?? [0])[0]),
            width: CGFloat(imageWidth),
            height: CGFloat(imageHeight)
        )

        return resultArray
    }

    /// Filters out all the results with confidence score < threshold and returns the top N results
    /// sorted in descending order.
    func formatResults(boundingBox: [Float], outputClasses: [Float], outputScores: [Float], outputCount: Int, width: CGFloat, height: CGFloat) -> [Inference]{
        var resultsArray: [Inference] = []
        if (outputCount == 0) {
            return resultsArray
        }
        for i in 0...outputCount - 1 {

            let score = outputScores[i]

            // Filters results with confidence < threshold.
            guard score >= self.threshold else {
                continue
            }

            // Gets the output class names for detected classes from labels list.
            let outputClassIndex = Int(outputClasses[i])
            let outputClass = self.labels[outputClassIndex + 1]

            var rect: CGRect = CGRect.zero

            // Translates the detected bounding box to CGRect.
            rect.origin.y = CGFloat(boundingBox[4*i])
            rect.origin.x = CGFloat(boundingBox[4*i+1])
            rect.size.height = CGFloat(boundingBox[4*i+2]) - rect.origin.y
            rect.size.width = CGFloat(boundingBox[4*i+3]) - rect.origin.x

            // The detected corners are for model dimensions. So we scale the rect with respect to the
            // actual image dimensions.
            let newRect = rect.applying(CGAffineTransform(scaleX: width, y: height))

            // Gets the color assigned for the class
            let colorToAssign = self.colorForClass(withIndex: outputClassIndex + 1)
            let inference = Inference(confidence: score, className: outputClass, rect: newRect, displayColor: colorToAssign)
            resultsArray.append(inference)
        }

        // Sort results in descending order of confidence.
        resultsArray.sort { (first, second) -> Bool in
            return first.confidence  > second.confidence
        }

        return resultsArray
    }

    /// Loads the labels from the labels file and stores them in the `labels` property.
    private func loadLabels(fileInfo: FileInfo) {
        let filename = fileInfo.name
        let fileExtension = fileInfo.extension
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            fatalError("Labels file not found in bundle. Please add a labels file with name " +
                       "\(filename).\(fileExtension) and try again.")
        }
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            self.labels = contents.components(separatedBy: .newlines)
        } catch {
            fatalError("Labels file named \(filename).\(fileExtension) cannot be read. Please add a " +
                       "valid labels file and try again.")
        }
    }

    /// Returns the RGB data representation of the given image buffer with the specified `byteCount`.
    ///
    /// - Parameters
    ///   - buffer: The BGRA pixel buffer to convert to RGB data.
    ///   - byteCount: The expected byte count for the RGB data calculated using the values that the
    ///       model was trained on: `batchSize * imageWidth * imageHeight * componentsCount`.
    ///   - isModelQuantized: Whether the model is quantized (i.e. fixed point values rather than
    ///       floating point values).
    /// - Returns: The RGB data representation of the image buffer or `nil` if the buffer could not be
    ///     converted.
    private func rgbDataFromBuffer(_ buffer: CVPixelBuffer, byteCount: Int, isModelQuantized: Bool) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width

        var sourceBuffer = vImage_Buffer(data: sourceData,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: sourceBytesPerRow)

        guard let destinationData = malloc(height * destinationBytesPerRow) else {
            print("Error: out of memory")
            return nil
        }

        defer {
            free(destinationData)
        }

        var destinationBuffer = vImage_Buffer(data: destinationData, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: destinationBytesPerRow)

        if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA){
            vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        } else if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32ARGB) {
            vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        }

        let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
        if isModelQuantized {
            return byteData
        }

        // Not quantized, convert to floats
        let bytes = Array<UInt8>(unsafeData: byteData)!
        var floats = [Float]()
        for i in 0..<bytes.count {
            floats.append((Float(bytes[i]) - self.imageMean) / self.imageStd)
        }
        return Data(copyingBufferOf: floats)
    }

    /// This assigns color for a particular class.
    private func colorForClass(withIndex index: Int) -> UIColor {

        // We have a set of colors and the depending upon a stride, it assigns variations to of the base
        // colors to each object based on its index.
        let baseColor = self.colors[index % colors.count]

        var colorToAssign = baseColor

        let percentage = CGFloat((self.colorStrideValue / 2 - index / self.colors.count) * self.colorStrideValue)

        if let modifiedColor = baseColor.getModified(byPercentage: percentage) {
            colorToAssign = modifiedColor
        }

        return colorToAssign
    }
}

// MARK: - Extensions

extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
}

extension Array {
    /// Creates a new array from the bytes of the given unsafe data.
    ///
    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
    ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
    ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
    ///     `MemoryLayout<Element>.stride`.
    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    }
}
