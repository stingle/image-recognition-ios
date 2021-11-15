//
//  ImagePredictor.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/11/21.
//

import Foundation

public class ImagePredictor {

    public struct Prediction {
        public let classification: String
        public let confidencePercentage: Float
    }

    private let tfImageClassifier = ObjectsModelDataHandler()
    private let assetImageGenerator = AssetImageGenerator()

    public init() {}

    public typealias ImagePredictionHandler = (_ predictions: [Prediction]?) -> Void

    public func makePredictions(for photo: UIImage, completionHandler: @escaping ImagePredictionHandler) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let pixelBuffer = CVPixelBuffer.buffer(from: photo) else {
                return
            }
            let result = self.tfImageClassifier?.runModel(onFrame: pixelBuffer)
            let predictions = result?.map({ Prediction(classification: $0.className, confidencePercentage: $0.confidence * 100) })
            DispatchQueue.main.async {
                completionHandler(predictions)
            }
        }
    }

    public func makePredictions(for video: URL, completionHandler: @escaping ImagePredictionHandler) {
        DispatchQueue.global(qos: .userInitiated).async {
            let frames = self.assetImageGenerator.getFramesFromVideo(url: video)
            var allPredictions = [Prediction]()
            for frame in frames {
                self.makePredictions(for: frame) { predictions in
                    if let predictions = predictions {
                        allPredictions.append(contentsOf: predictions)
                    }
                }
            }
            DispatchQueue.main.async {
                completionHandler(allPredictions)
            }
        }
    }
    
}
