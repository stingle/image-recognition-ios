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
    var faces: [FaceObject]!

    private let database = PreviewDatabase.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFit
        self.image = self.image.fixOrientation()
        self.imageView.image = self.image
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for face in self.faces {
            self.drawFaceboundingBox(face: face.face, boundingBox: face.bounds)
        }
    }

    // MARK: - Private methods

    func drawFaceboundingBox(face: Face, boundingBox: CGRect) {
        let imageRect = self.imageView.contentClippingRect
        let x = boundingBox.origin.x * imageRect.width + imageRect.origin.x
        let y = boundingBox.origin.y * imageRect.height + imageRect.origin.y
        let width = boundingBox.width * imageRect.width
        let height = boundingBox.height * imageRect.height
        self.createLayer(in: CGRect(x: x, y: y, width: width, height: height), face: face)
    }

    private func createLayer(in rect: CGRect, face: Face) {
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.cornerRadius = 5
        mask.opacity = 1.0
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0
        self.imageView.layer.insertSublayer(mask, at: 1)
        self.addNameButton(in: rect, face: face)
    }

    private func addNameButton(in rect: CGRect, face: Face) {
        let y = self.imageView.frame.origin.y + rect.origin.y - 30.0
        let button = UIButton(frame: CGRect(x: rect.origin.x - 20.0, y: y, width: rect.width + 40.0, height: 30.0))
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 9.0)
        button.setTitleColor(.red, for: .normal)
        button.restorationIdentifier = face.identifier
        let name = face.name?.isEmpty ?? true ? "undefined" : face.name
        button.setTitle(name, for: .normal)
        button.addTarget(self, action: #selector(nameButtonPressed(button:)), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc func nameButtonPressed(button: UIButton) {
        let face = self.faces.first(where: { $0.face.identifier == button.restorationIdentifier })?.face
        let name = face?.name
        let alert = UIAlertController(title: "Name", message: "Please enter the person name.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = name
            textField.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Set", style: .default, handler: { _ in
            face?.name = alert.textFields?.first?.text
            let name = face?.name?.isEmpty ?? true ? "undefined" : face?.name
            button.setTitle(name, for: .normal)
        }))
        self.present(alert, animated: true)
    }

}
