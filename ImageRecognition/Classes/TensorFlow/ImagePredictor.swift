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

    public init() {}

    public typealias ImagePredictionHandler = (_ predictions: [Prediction]?) -> Void

    public func makePredictions(for photo: UIImage, completionHandler: @escaping ImagePredictionHandler) throws {
        guard let pixelBuffer = CVPixelBuffer.buffer(from: photo) else {
            return
        }
        let result = self.tfImageClassifier?.runModel(onFrame: pixelBuffer)
        let predictions = result?.map({ Prediction(classification: $0.className, confidencePercentage: $0.confidence * 100) })
        completionHandler(predictions)
    }

}

