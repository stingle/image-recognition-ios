//
//  FaceDetectionViewController.swift
//  Example
//
//  Created by Shahen Antonyan on 10/22/21.
//

import UIKit
import ARKit

class FaceDetectionViewController: ImagePickerViewController {

    @IBOutlet weak var imageSegmentedView: UIView!
    @IBOutlet weak var liveSegmentedView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sceneView: ARSCNView!

    private var maskLayer = [CAShapeLayer]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Face Detection"
        self.sceneView.showsStatistics = true
        self.imageView.contentMode = .scaleAspectFit
    }

    func drawFaceboundingBox(face : VNFaceObservation) {

        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.imageView.imageRect.height)

        let translate = CGAffineTransform.identity.scaledBy(x: self.imageView.imageRect.width, y: self.imageView.imageRect.height)

        // The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
        var facebounds = face.boundingBox.applying(translate).applying(transform)
        facebounds.origin.y += self.imageView.imageRect.origin.y
        _ = createLayer(in: facebounds)

    }

    // Create a new layer drawing the bounding box
    private func createLayer(in rect: CGRect) -> CAShapeLayer{

        let mask = CAShapeLayer()
        mask.frame = rect
        mask.cornerRadius = 10
        mask.opacity = 0.75
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0

        maskLayer.append(mask)
        self.imageView.layer.insertSublayer(mask, at: 1)

        return mask
    }

    override func didSelectImage(image: UIImage) {
        self.imageView.image = image
        guard let ciImage = CIImage(image: image) else {
            return
        }

        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            DispatchQueue.main.async {
                for face in faces {
                    self.drawFaceboundingBox(face: face)
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try VNSequenceRequestHandler().perform([request], on: ciImage)
            } catch {
                print(error)
            }
        }
    }

    // MARK: - Actions

    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.imageSegmentedView.isHidden = false
            self.liveSegmentedView.isHidden = true
            self.sceneView.session.pause()
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.imageSegmentedView.isHidden = true
            self.liveSegmentedView.isHidden = false
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    @IBAction func addButtonAction(_ sender: Any) {
        self.presentPhotoPicker()
    }
}

extension FaceDetectionViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let device = self.sceneView.device else {
            return nil
        }
        let faceGeometry = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceGeometry)
        node.geometry?.firstMaterial?.fillMode = .lines
        return node
    }


    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
            return
        }
        faceGeometry.update(from: faceAnchor.geometry)

        /*guard let model = try? VNCoreMLModel(for: People(configuration: MLModelConfiguration()).model) else {
            fatalError("Unable to load model")
        }

        let coreMlRequest = VNCoreMLRequest(model: model) {[weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Unexpected results")
            }
//            DispatchQueue.main.async {[weak self] in
//                for result in results {
//                    guard let label = FaceClassificationLabel(rawValue: observations[0].identifier) else {
//                        self.transitionToErrorState()
//                        return
//                    }
//                    let prediction = Prediction(classification: result.identifier, confidencePercentage: result.confidencePercentageString)
//                }
//                self?.nameLabel.text = topResult.identifier
//            }
        }

        coreMlRequest.imageCropAndScaleOption = .centerCrop
        guard let pixelBuffer = self.sceneView.session.currentFrame?.capturedImage else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([coreMlRequest])
            } catch {
                print(error)
            }
        }*/
    }

}

extension UIImageView {

    var imageRect: CGRect {
        let imageViewSize = self.frame.size
        let imgSize = self.image?.size
        guard let imageSize = imgSize else { return CGRect.zero }
        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)
        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2
        imageRect.origin.x += self.frame.origin.x
        imageRect.origin.y += self.frame.origin.y
        return imageRect
    }

}
