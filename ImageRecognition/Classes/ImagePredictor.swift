//
//  ImagePredictor.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 18.10.21.
//

import Vision
import UIKit

public class ImagePredictor {

    public struct Prediction {
        public let classification: String
        public let confidencePercentage: String
    }

    private let imageClassifier: VNCoreMLModel

    public init(model: MLModel) {
        // Create a Vision instance using the image classifier's model instance.
        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: model) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        self.imageClassifier = imageClassifierVisionModel
    }

    public typealias ImagePredictionHandler = (_ predictions: [Prediction]?) -> Void

    private var predictionHandlers = [VNRequest: ImagePredictionHandler]()

    private func createImageClassificationRequest() -> VNImageBasedRequest {
        let imageClassificationRequest = VNCoreMLRequest(model: self.imageClassifier, completionHandler: visionRequestHandler)
        imageClassificationRequest.imageCropAndScaleOption = .centerCrop
        return imageClassificationRequest
    }

    public func makePredictions(for photo: UIImage, completionHandler: @escaping ImagePredictionHandler) throws {
        let orientation = CGImagePropertyOrientation(photo.imageOrientation)
        guard let photoImage = photo.cgImage else {
            fatalError("Photo doesn't have underlying CGImage.")
        }
        let imageClassificationRequest = createImageClassificationRequest()
        self.predictionHandlers[imageClassificationRequest] = completionHandler
        let handler = VNImageRequestHandler(cgImage: photoImage, orientation: orientation)
        let requests: [VNRequest] = [imageClassificationRequest]
        try handler.perform(requests)
    }

    // MARK: - Private methods

    private func visionRequestHandler(_ request: VNRequest, error: Error?) {
        // Remove the caller's handler from the dictionary and keep a reference to it.
        guard let predictionHandler = predictionHandlers.removeValue(forKey: request) else {
            fatalError("Every request must have a prediction handler.")
        }
        var predictions: [Prediction]? = nil
        defer {
            predictionHandler(predictions)
        }
        if let error = error {
            print("Vision image classification error...\n\n\(error.localizedDescription)")
            return
        }
        if request.results == nil {
            print("Vision request had no results.")
            return
        }
        guard let observations = request.results as? [VNClassificationObservation] else {
            print("VNRequest produced the wrong result type: \(type(of: request.results)).")
            return
        }
        predictions = observations.map { observation in
            Prediction(classification: observation.identifier, confidencePercentage: observation.confidencePercentageString)
        }
    }
}

