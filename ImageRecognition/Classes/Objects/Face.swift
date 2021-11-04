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
    public let pixelBuffer: [Float32]

    internal init(boundingBox: CGRect, image: UIImage, pixelBuffer: [Float32]) {
        self.boundingBox = boundingBox
        self.image = image
        self.pixelBuffer = pixelBuffer
    }

}

extension Face: Hashable {
    public static func == (lhs: Face, rhs: Face) -> Bool {
        return lhs.boundingBox == rhs.boundingBox && lhs.image == rhs.image
    }


    public func hash(into hasher: inout Hasher) {
        let boundingBoxString = "\(self.boundingBox.origin.x):\(self.boundingBox.origin.y)-\(self.boundingBox.width):\(self.boundingBox.height)"
        hasher.combine(boundingBoxString)
        hasher.combine(self.image)
    }

}
