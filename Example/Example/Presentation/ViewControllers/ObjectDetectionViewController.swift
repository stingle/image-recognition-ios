//
//  ObjectDetectionViewController.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 14.10.21.
//

import UIKit
import Vision
import ImageRecognition
import PhotosUI
import AVKit

class ObjectDetectionViewController: ImagePickerViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionTextView: UITextView!
    @IBOutlet weak var livePhotoView: PHLivePhotoView!
    @IBOutlet weak var playButton: UIButton!

    private let objectDetector: ObjectDetector = ObjectDetector()

    let minimumConfidencePercentage : Float = 25
    var topPredictions = [String: String]()

    private var videoURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.livePhotoView.contentMode = .scaleAspectFit
        self.title = "Object Detection"
    }

    override func didSelectImage(image: UIImage) {
        self.topPredictions.removeAll()
        self.updateImage(image)
        self.updatePredictionLabel("Making predictions for the image...")

        self.objectDetector.makePredictions(forImage: image, completionHandler: self.predictionHandler)
    }

    override func didSelectLivePhoto(livePhoto: PHLivePhoto) {
        self.imageView.isHidden = true
        self.playButton.isHidden = false
        self.livePhotoView.isHidden = false
        self.livePhotoView.livePhoto = livePhoto
        self.livePhotoView.startPlayback(with: .full)
        self.updatePredictionLabel("Making predictions for the live photo...")

        self.objectDetector.makePredictions(forLivePhoto: livePhoto, completionHandler: self.predictionHandler)
    }

    override func didSelectVideo(videoURL: URL) {
        self.videoURL = videoURL
        let assetImageGenerator = AssetImageGenerator()
        guard let image = try? assetImageGenerator.generateThumnail(videoURL: videoURL, fromTime: 0.0) else {
            return
        }
        self.imageView.image = image
        self.livePhotoView.isHidden = true
        self.imageView.isHidden = false
        self.playButton.isHidden = false
        self.livePhotoView.livePhoto = nil
        self.topPredictions.removeAll()
        self.updatePredictionLabel("Making predictions for the video...")

        self.objectDetector.makePredictions(forVideo: videoURL, completionHandler: self.videoPredictionHandler)
    }

    override func didSelectGIF(url: URL) {
        self.livePhotoView.isHidden = true
        self.imageView.isHidden = false
        self.playButton.isHidden = true
        self.livePhotoView.livePhoto = nil
        self.imageView.image = UIImage.animatedImageFromGIF(url: url)

        self.topPredictions.removeAll()
        self.updatePredictionLabel("Making predictions for the gif...")

        self.objectDetector.makePredictions(forGIF: url, completionHandler: self.predictionHandler)
    }

    // MARK: - Action

    @IBAction func addButtonAction(_ sender: Any) {
        self.requestAuthorization { allowed in
            if allowed {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { _ in
                    self.openPhotoGallery()
                }))
                alert.addAction(UIAlertAction(title: "Choose Video", style: .default, handler: { _ in
                    self.openVideoGallery()
                }))
                alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
                self.present(alert, animated: true)
            }
        }
    }

    @IBAction func playButtonAction(_ sender: Any) {
        if let videoURL = self.videoURL {
            let player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        } else if self.livePhotoView.livePhoto != nil {
            self.livePhotoView.startPlayback(with: .full)
        }
    }

    // MARK: - Private methods

    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status == .authorized)
                }
            }
            return
        }
        completion(true)
    }

    private func predictionHandler(_ predictions: [ObjectDetector.Prediction]?) {
        DispatchQueue.main.async {
            guard let predictions = predictions else {
                self.updatePredictionLabel("No predictions. (Check console log.)")
                return
            }

            let formattedPredictions = self.formatPredictions(predictions)
            let predictionString = formattedPredictions.map({ $0.key + " " + $0.value }).joined(separator: "\n")
            print(predictionString)
            self.updatePredictionLabel(predictionString)
        }
    }

    private func videoPredictionHandler(_ predictions: [ObjectDetector.Prediction]?) {
        DispatchQueue.main.async {
            guard let predictions = predictions else {
                self.updatePredictionLabel("No predictions. (Check console log.)")
                return
            }

            let formattedPredictions = self.formatPredictions(predictions)
            let predictionString = formattedPredictions.map({ $0.key + " " + $0.value }).joined(separator: "\n")
            self.updatePredictionLabel(predictionString)
        }
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

    private func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.livePhotoView.livePhoto = nil
            self.imageView.isHidden = false
            self.livePhotoView.isHidden = true
            self.playButton.isHidden = true
            self.imageView.image = image
        }
    }

    private func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.predictionTextView.text = message
            self.predictionTextView.isHidden = false
        }
    }

}
