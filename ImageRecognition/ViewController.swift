//
//  ViewController.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 14.10.21.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var verdictLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let captureSesstion = AVCaptureSession()
        captureSesstion.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let inptut = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSesstion.addInput(inptut)
        captureSesstion.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSesstion)
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSesstion.addOutput(dataOutput)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        //todo configure cpu gpu all //natural engine
        //MobileNet.mlkitmodel
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq , err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
//            print(results)
            guard let firsObservation = results.first else { return }
            let percentOfConfidence = (firsObservation.confidence * 100).rounded() / 100
//            print(firsObservation.identifier, " ", percentOfConfidence)
            print(results[0].identifier, (results[0].confidence*100).rounded()/100)
            print(results[1].identifier, (results[1].confidence*100).rounded()/100)
            print(results[2].identifier, (results[2].confidence*100).rounded()/100)
            DispatchQueue.main.async {
                self.verdictLabel.text = firsObservation.identifier + " " + String(percentOfConfidence)
            }
            
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}
