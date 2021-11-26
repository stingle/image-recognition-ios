//
//  FaceDetector.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision
import Photos

public class FaceDetector {

    private var modelDataHandler: FacenetModelDataHandler?

    private let assetImageGenerator = AssetImageGenerator()

    private var dispatchQueue: DispatchQueue

    var testFrameTook = 0.0 {
        didSet {
            if testFrameTook == 0.0 {
                return
            }
            self.checkNextFrame()
        }
    }
    
    private var lastFrameChecked = 0
    
    private var detectionStarted = 0.0
    
    private var maximumDurationOfPredictionsForGifLive = 1000.0 // in milliseconds

    var imagesForDetection = [UIImage]()

    var allFaces = [(face: Face, bounds: CGRect)]()

    public init(modelFileInfo: FileInfo = MobileNet.faceModelInfo, threadCount: Int = 4, queue: DispatchQueue? = nil) {
        self.dispatchQueue = queue ?? DispatchQueue.global(qos: .userInitiated)
        self.modelDataHandler = FacenetModelDataHandler(modelFileInfo: modelFileInfo)
    }

    public func detectFaces(fromImage image: UIImage, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.visionDetectFace(from: image, completion: completion)
    }

    public func detectFaces(fromVideo videoURL: URL, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        let frames = self.assetImageGenerator.getFramesFromVideo(url: videoURL)
        self.detectFaces(fromImages: frames, completion: completion)
    }

    public func detectFaces(fromLivePhoto livePhoto: PHLivePhoto, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.assetImageGenerator.getImagesFromLivePhoto(livePhoto: livePhoto) { images in
            self.detectFaces(fromImages: images, completion: completion)
        }
    }

    public func detectFaces(fromGIF gifURL: URL, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        let images = self.assetImageGenerator.getImagesFromGIF(url: gifURL)
        self.detectFaces(fromImages: images, completion: completion)
    }

    // MARK: - Private methods
    func checkDetectionDurationAndDetect() {
        detectionStarted = Date().timeIntervalSince1970 * 1000
        let image = imagesForDetection[lastFrameChecked]
        
        self.visionDetectFace(from: image) { result in
            switch result {
            case .success(let faces):
                self.allFaces.append(contentsOf: faces)
                print("success")
                self.testFrameTook = Date().timeIntervalSince1970 * 1000 - self.detectionStarted
            case .failure(_):
                print("fail")
                self.testFrameTook = Date().timeIntervalSince1970 * 1000 - self.detectionStarted
            }
        }
    }
    
    func checkNextFrame() {
        if (Date().timeIntervalSince1970 * 1000 - detectionStarted  + testFrameTook) < maximumDurationOfPredictionsForGifLive {
            let startOfCurrentDetection = Date().timeIntervalSince1970 * 1000
            let timeLeft = maximumDurationOfPredictionsForGifLive - (startOfCurrentDetection - detectionStarted)
            var checksLeft = (timeLeft/testFrameTook)
            checksLeft.round(.down)
            let step = (imagesForDetection.count - lastFrameChecked) / Int(checksLeft)
            if lastFrameChecked + step > imagesForDetection.count - 1 {
                print("finish here ", self.allFaces.count)
                lastFrameChecked = 0
                detectionStarted = 0.0
                testFrameTook = 0.0
                imagesForDetection = [UIImage]()
                allFaces = [(face: Face, bounds: CGRect)]()
                return
            }

            let nextImage = imagesForDetection[lastFrameChecked + step]
            lastFrameChecked = lastFrameChecked + step
            self.visionDetectFace(from: nextImage) { result in
                switch result {
                case .success(let faces):
                    self.allFaces.append(contentsOf: faces)
                    self.testFrameTook = Date().timeIntervalSince1970 * 1000 - startOfCurrentDetection
                case .failure(_):
                    self.testFrameTook = Date().timeIntervalSince1970 * 1000 - startOfCurrentDetection
                }
            }

        }
    }

    private func detectFaces(fromImages: [UIImage], completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.imagesForDetection = fromImages
        checkDetectionDurationAndDetect()
    }

    private func recognize(image: UIImage) throws -> [Float32] {
        guard let pixelBuffer = CVPixelBuffer.pixelBuffer(from: image) else {
            return []
        }
        let result = self.modelDataHandler?.runModel(onFrame: pixelBuffer)
        return result ?? []
    }

    private func face(from ciImage: CIImage, bounds: CGRect) throws -> Face {
        let croppedImage = ciImage.cropped(to: bounds)
        guard let newImage = croppedImage.toUIImage() else {
            throw FaceDetectorError.failed
        }
        let resized = newImage.resized()
        let pixelArray = try self.recognize(image: resized)
        return Face(image: resized, pixelBuffer: pixelArray)
    }

    private func visionDetectFace(from image: UIImage, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        guard let image = image.fixOrientation(), let ciImage = CIImage(image: image) else {
            completion(.failure(.badImage))
            return
        }
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            var detectedFaces = [(Face, CGRect)]()
            for face in faces {
                let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(image.size.width), Int(image.size.height))
                do {
                    guard let face = try self?.face(from: ciImage, bounds: rect) else {
                        return
                    }
                    var boundingBox = CGRect(x: rect.origin.x / image.size.width, y: rect.origin.y / image.size.height, width: rect.width / image.size.width, height: rect.height / image.size.height)
                    boundingBox.origin.y = 1 - boundingBox.maxY
                    detectedFaces.append((face, boundingBox))
                } catch {
                    completion(.failure(.failed))
                }
            }
            completion(.success(detectedFaces))
        }
        self.dispatchQueue.async {
            do {
                try VNSequenceRequestHandler().perform([request], on: ciImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
            } catch {
                completion(.failure(.failed))
            }
        }
    }
}
