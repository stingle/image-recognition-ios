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

    var accuracyOfPrediction = 1.0 //0-1, 1 means - 100% allowed duration of prediction usage
    
    private var maximumDurationOfPredictions = 20000.0 // in milliseconds
    
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

    public func makePredictions(forVideo video: URL, completionHandler: @escaping VideoPredictionHandler) {
        self.dispatchQueue.async {
            let framesCanGet = self.framesCanGetFromVideo(video: video, completionHandler: completionHandler)
            let asset = AVURLAsset(url: video)
            let durationInSeconds = asset.duration.seconds
            let stepForFrame = durationInSeconds/Double(framesCanGet)
            if (framesCanGet > 1) {
                for i in 1...Int(framesCanGet)-1 {
                    let tsForFrame = Double(i) * stepForFrame
                    let frame = self.assetImageGenerator.getFrameFromVideoForTime(url: video, time: tsForFrame)
                    guard let predictionsForFrame = self.predictions(for: frame) else { continue }
                    completionHandler(predictionsForFrame)
                }
            }
        }
    }

    func framesCanGetFromVideo(video: URL, completionHandler: @escaping VideoPredictionHandler)->Double {
        let startOfTest = Date().timeIntervalSince1970 * 1000
        let firstFrame = self.assetImageGenerator.getFrameFromVideoForTime(url: video, time: 0)
        let predictionForFirstFrame = self.predictions(for: firstFrame)
        completionHandler(predictionForFirstFrame)
        let endOfTest = Date().timeIntervalSince1970 * 1000
        let testFramePredictionDuration = endOfTest - startOfTest
        
        let allowedDurationOfPrediction = self.maximumDurationOfPredictions * self.accuracyOfPrediction
        var framesCanGet = allowedDurationOfPrediction / (testFramePredictionDuration*1.3)
        framesCanGet.round(.down)
        
        return framesCanGet
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
