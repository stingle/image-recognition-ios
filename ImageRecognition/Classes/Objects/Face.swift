//
//  Face.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision

public class Face {
    public let boundingBox: CGRect
    public let image: UIImage
    public let features: FaceFeatures

    internal init(boundingBox: CGRect, image: UIImage, features: FaceFeatures) {
        self.boundingBox = boundingBox
        self.image = image
        self.features = features
    }

    public static func ==(lhs: Face, rhs: Face) -> Bool {
        return lhs.features == rhs.features
    }

}
