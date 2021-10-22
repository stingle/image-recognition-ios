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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Face Detection"
        self.sceneView.showsStatistics = true
    }

    override func didSelectImage(image: UIImage) {
        self.imageView.image = image
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
        guard let device = sceneView.device else {
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

        guard let model = try? VNCoreMLModel(for: People(configuration: MLModelConfiguration()).model) else {
            fatalError("Unable to load model")
        }
        let coreMlRequest = VNCoreMLRequest(model: model) {[weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                fatalError("Unexpected results")
            }
            DispatchQueue.main.async {[weak self] in
//                for result in request.results ?? [] {
//                    if let faceObs = result as? VNClassificationObservation {
//                        print("find")
//                    }
//                }
//                self?.nameLabel.text = topResult.identifier
            }
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
        }
    }

}
