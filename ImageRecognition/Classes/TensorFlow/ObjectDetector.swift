//
//  ObjectDetector.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/11/21.
//

import Foundation
import Photos
import VideoToolbox

public class ObjectDetector {

    public struct Prediction {
        public let classification: String
        public let confidencePercentage: Float
    }

    private let imageClassifier: ObjectsModelDataHandler?

    private let assetImageGenerator = AssetImageGenerator()

    private var dispatchQueue: DispatchQueue

    private var isDetectionInProgress = false
    
    public init(modelFileInfo: FileInfo = MobileNet.objectModelInfo, labelsFileInfo: FileInfo = MobileNet.objectsLabelsInfo, queue: DispatchQueue? = nil) {
        self.dispatchQueue = queue ?? DispatchQueue.global(qos: .userInitiated)
        self.imageClassifier = ObjectsModelDataHandler(modelFileInfo: modelFileInfo, labelsFileInfo: labelsFileInfo)
    }

    public typealias ImagePredictionHandler = (_ predictions: [Prediction]?) -> Void
   
    public typealias VideoPredictionHandler = (_ predictions: [Prediction]?) -> Void

    public func makePredictions(forImage image: UIImage, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            completionHandler(self.predictions(for: image))
        }
    }

    public func makePredictions(forVideo videoURL: URL, configuration: Configuration = Configuration(), completionHandler: @escaping VideoPredictionHandler) {
        self.dispatchQueue.async {
            guard !self.isDetectionInProgress else { return }
            self.isDetectionInProgress = true
            self.configureAssetGeneration(fromVideo: videoURL, configuration: configuration) {
                var results = [Prediction]()
                self.predictionsRecursively(fromVideo: videoURL) { predictions, isFinished in
                    if let predictions = predictions {
                        results.append(contentsOf: predictions)
                    }
                    if isFinished {
                        self.isDetectionInProgress = isFinished
                        completionHandler(results)
                    }
                }
            }
        }
    }

    public func makePredictions(forLivePhoto livePhoto: PHLivePhoto, maxProcessingImagesCount: Int = 5, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            guard !self.isDetectionInProgress else { return }
            self.isDetectionInProgress = true

            self.assetImageGenerator.getImagesFromLivePhoto(livePhoto: livePhoto) { images in
                guard !images.isEmpty else {
                    self.isDetectionInProgress = false
                    return
                }
                let presictions = self.predictions(fromImages: images, maxProcessingImagesCount: maxProcessingImagesCount)
                completionHandler(presictions)
            }
        }
    }

    public func makePredictions(forGIF gifURL: URL, maxProcessingImagesCount: Int = 5, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            guard !self.isDetectionInProgress else { return }
            self.isDetectionInProgress = true

            let images = self.assetImageGenerator.getImagesFromGIF(url: gifURL)
            guard !images.isEmpty else {
                self.isDetectionInProgress = false
                return
            }
            let presictions = self.predictions(fromImages: images, maxProcessingImagesCount: maxProcessingImagesCount)
            completionHandler(presictions)
        }
    }

    // MARK: - Private methods

    private func configureAssetGeneration(fromVideo videoURL: URL, configuration: Configuration, completion: @escaping () -> Void) {
        self.assetImageGenerator.configure(videoURL: videoURL, configuration: configuration)
        if let image = try? self.assetImageGenerator.generateThumnail(url: videoURL, fromTime: 0.0) {
            self.predictions(for: image)
            let frameDetectionStarted = self.assetImageGenerator.frameDetectionStartedForFace
            let frameDetectionEnded = Date().timeIntervalSince1970 * 1000
            self.assetImageGenerator.oneFramePredictionTime = frameDetectionEnded - frameDetectionStarted
            completion()
        } else {
            self.assetImageGenerator.oneFramePredictionTime = 720.0
            completion()
        }
    }

    private func predictionsRecursively(fromVideo videoURL: URL, completion: @escaping ([Prediction]?, Bool) -> Void) {
        do {
            if let image = try self.assetImageGenerator.faceDetectionFromSource(videoURL: videoURL) {
                let predictions = self.predictions(for: image)
                let frameDetectionEnded = Date().timeIntervalSince1970 * 1000
                self.assetImageGenerator.oneFramePredictionTime = frameDetectionEnded - self.assetImageGenerator.frameDetectionStartedForFace
                completion(predictions, false)
                self.predictionsRecursively(fromVideo: videoURL, completion: completion)
            } else {
                completion(nil, true)
            }
        } catch {
            self.predictionsRecursively(fromVideo: videoURL, completion: completion)
        }
    }

    private func predictions(fromImages: [UIImage], maxProcessingImagesCount: Int) -> [Prediction] {
        let by = fromImages.count / min(maxProcessingImagesCount, fromImages.count)
        var results = [Prediction]()
        for i in stride(from: 0, to: fromImages.count, by: by) {
            let image = fromImages[i]
            guard let predictions = self.predictions(for: image) else { continue }
            results.append(contentsOf: predictions)
        }
        return results
    }

    @discardableResult
    private func predictions(for photo: UIImage) -> [Prediction]? {
        guard let pixelBuffer = CVPixelBuffer.pixelBuffer(from: photo) else {
            return nil
        }
        let result = self.imageClassifier?.runModel(onFrame: pixelBuffer)
        return result?.map({ Prediction(classification: $0.className, confidencePercentage: $0.confidence * 100) })
    }

}
