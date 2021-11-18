//
//  ObjectDetector.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/11/21.
//

import Foundation
import Photos

public class ObjectDetector {

    public struct Prediction {
        public let classification: String
        public let confidencePercentage: Float
    }

    private let imageClassifier: ObjectsModelDataHandler?

    private let assetImageGenerator = AssetImageGenerator()

    private var dispatchQueue: DispatchQueue

    public init(modelFileInfo: FileInfo = MobileNet.objectModelInfo, labelsFileInfo: FileInfo = MobileNet.objectsLabelsInfo, queue: DispatchQueue? = nil) {
        self.dispatchQueue = queue ?? DispatchQueue.global(qos: .userInitiated)
        self.imageClassifier = ObjectsModelDataHandler(modelFileInfo: modelFileInfo, labelsFileInfo: labelsFileInfo)
    }

    public typealias ImagePredictionHandler = (_ predictions: [Prediction]?) -> Void

    public func makePredictions(forImage image: UIImage, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            completionHandler(self.predictions(for: image))
        }
    }

    public func makePredictions(forVideo video: URL, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            let frames = self.assetImageGenerator.getFramesFromVideo(url: video)
            var allPredictions = [Prediction]()
            for frame in frames {
                guard let predictions = self.predictions(for: frame) else { continue }
                allPredictions.append(contentsOf: predictions)
            }
            completionHandler(allPredictions)
        }
    }

    public func makePredictions(forLivePhoto livePhoto: PHLivePhoto, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            self.assetImageGenerator.getImagesFromLivePhoto(livePhoto: livePhoto) { images in
                var allPredictions = [Prediction]()
                for image in images {
                    guard let predictions = self.predictions(for: image) else { continue }
                    allPredictions.append(contentsOf: predictions)
                }
                completionHandler(allPredictions)
            }
        }
    }

    public func makePredictions(forGIF gifURL: URL, completionHandler: @escaping ImagePredictionHandler) {
        self.dispatchQueue.async {
            let images = self.assetImageGenerator.getImagesFromGIF(url: gifURL)
            var allPredictions = [Prediction]()
            for image in images {
                guard let predictions = self.predictions(for: image) else { continue }
                allPredictions.append(contentsOf: predictions)
            }
            completionHandler(allPredictions)
        }
    }

    // MARK: - Private methods

    private func predictions(for photo: UIImage) -> [Prediction]? {
        guard let pixelBuffer = CVPixelBuffer.buffer(from: photo) else {
            return nil
        }
        let result = self.imageClassifier?.runModel(onFrame: pixelBuffer)
        return result?.map({ Prediction(classification: $0.className, confidencePercentage: $0.confidence * 100) })
    }

}
