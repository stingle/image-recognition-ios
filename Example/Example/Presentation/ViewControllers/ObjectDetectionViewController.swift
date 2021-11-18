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

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!

    let imagePredictor: ObjectDetector = ObjectDetector()

    let minimumConfidencePercentage : Float = 25
    var topPredictions = [String: String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Object Detection"
    }

    override func didSelectImage(image: UIImage) {
        self.topPredictions.removeAll()
        self.updateImage(image)
        self.updatePredictionLabel("Making predictions for the image...")

        self.imagePredictor.makePredictions(for: image, completionHandler: self.predictionHandler)
    }

    override func didSelectVideo(videoURL: URL) {
        self.topPredictions.removeAll()
        self.updatePredictionLabel("Making predictions for the video...")

        self.imagePredictor.makePredictions(for: videoURL, completionHandler: self.predictionHandler)
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
            self.predictionLabel.isHidden = false
        }
    }

    @IBAction func addButtonAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: { _ in
            self.openPhotoGallery()
        }))
        alert.addAction(UIAlertAction(title: "Choose video", style: .default, handler: { _ in
            self.openVideoGallery()
        }))
        alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        self.present(alert, animated: true)
    }

    // MARK: - Private methods

    private func predictionHandler(_ predictions: [ObjectDetector.Prediction]?) {
        guard let predictions = predictions else {
            self.updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)
        let predictionString = formattedPredictions.map({ $0.key + " " + $0.value }).joined(separator: "\n")
        print(predictionString)
        self.updatePredictionLabel(predictionString)
    }

    private func percentageToString(_ percentage: Float) -> String {
        switch percentage {
        case 100.0...:
            return "100%"
        case 10.0..<100.0:
            return String(format: "%2.1f%%", percentage)
        case 1.0..<10.0:
            return String(format: "%2.1f%%", percentage)
        case ..<1.0:
            return String(format: "%1.2f%%", percentage)
        default:
            return String(format: "%2.1f%%", percentage)
        }
    }

    private func formatPredictions(_ predictions: [ObjectDetector.Prediction]) -> [String:String] {
        for prediction in predictions {
            if prediction.confidencePercentage > self.minimumConfidencePercentage {
                var name = prediction.classification
                if let firstComma = name.firstIndex(of: ",") {
                    name = String(name.prefix(upTo: firstComma))
                }
                if !self.topPredictions.keys.contains(prediction.classification) {
                    self.topPredictions[prediction.classification] = self.percentageToString(prediction.confidencePercentage)
                }
            }
        }
        
        if self.topPredictions.count == 0 {
            self.topPredictions["no matches"] = "0"
        }
        
        if (self.topPredictions.count > 1 && self.topPredictions["no matches"] != nil) {
            self.topPredictions.removeValue(forKey: "no matches")
        }
        
        return self.topPredictions
    }

}
