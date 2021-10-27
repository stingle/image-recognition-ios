//
//  ImageViewController.swift
//  Example
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import ImageRecognition
import Vision

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!

    var image: UIImage!
    var faces: [Face]!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFit
        self.image = self.image.fixOrientation()
        self.imageView.image = self.image
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for face in faces {
            self.drawFaceboundingBox(boundingBox: face.boundingBox)
        }
    }

    // MARK: - Private methods

    func drawFaceboundingBox(boundingBox: CGRect) {
        let imageRect = self.imageView.contentClippingRect
        let x = boundingBox.origin.x * imageRect.width + imageRect.origin.x
        let y = (1 - boundingBox.maxY) * imageRect.height + imageRect.origin.y
        let width = boundingBox.width * imageRect.width
        let height = boundingBox.height * imageRect.height
        self.createLayer(in: CGRect(x: x, y: y, width: width, height: height))
    }

    private func createLayer(in rect: CGRect) {
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.cornerRadius = 5
        mask.opacity = 1.0
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0
        self.imageView.layer.insertSublayer(mask, at: 1)
    }
    
}
