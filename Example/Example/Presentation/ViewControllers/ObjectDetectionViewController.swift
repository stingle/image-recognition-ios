//
//  ObjectDetectionViewController.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 14.10.21.
//

import UIKit
import Vision
import ImageRecognition

class ObjectDetectionViewController: ImagePickerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Object Detection"
    }

    let imagePredictor: ImagePredictor = {
        let defaultConfig = MLModelConfiguration()
        let imageClassifierWrapper = try? MobileNet(configuration: defaultConfig)
        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }
        let predictor = ImagePredictor(model: imageClassifier.model)
        return predictor
    }()

    let minimumConfidencePercentage : Float = 10
    
    // MARK: Main storyboard outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    // MARK: Main storyboard actions
    @IBAction func singleTap() {
        presentPhotoPicker()
    }
    
    @IBAction func doubleTap() {
        openVideoGallery()
    }

    // MARK: Main storyboard updates
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.predictionLabel.text = message
        }
    }

    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("Making predictions for the photo...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }
    
    func userSelectedFrames(_ frames: [UIImage?]) {
        if frames.count > 0 {
            updateImage(frames[0]!)
            updatePredictionLabel("Making predictions for the video...")

            DispatchQueue.global(qos: .userInitiated).async {
                for i in 0..<frames.count {
                    self.classifyFrame(frames[i]!)
                }
            }
        } else {
            updatePredictionLabel("No frames in video...")
        }
        
    }

    override func didSelectImage(image: UIImage) {
        self.userSelectedPhoto(image)
    }
    
    override func didSelectFrames(frames: [UIImage?]) {
        self.userSelectedFrames(frames)
    }

    
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                       completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    /// Sends a frame to the Image Predictor to get a prediction of its content.
    /// - Parameter frame: A photo.
    private func classifyFrame(_ frame: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: frame,
                                                    completionHandler: framePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    
    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.keys.joined(separator: "\n")
        updatePredictionLabel(predictionString)
    }
    
    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: framePredictionHandler
    private func framePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }
        //todo continue from here
        //collect new predictions, ignore ignore repetitive. Once all frames checked - update label
        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.keys.joined(separator: "\n")
//        updatePredictionLabel(predictionString)
    }

    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String:String] {
        var topPredictions = [String:String]() as Dictionary
        for prediction in predictions {
            if Float(prediction.confidencePercentage)! > minimumConfidencePercentage {
                var name = prediction.classification
                if let firstComma = name.firstIndex(of: ",") {
                    name = String(name.prefix(upTo: firstComma))
                }
                if !topPredictions.keys.contains(prediction.classification) {
                    topPredictions[prediction.classification] = prediction.confidencePercentage
                }
            } else {
                if topPredictions.count == 0 {
                    topPredictions["no matches"] = "0"
                }
                return topPredictions
            }
        }
        return topPredictions
    }

}
