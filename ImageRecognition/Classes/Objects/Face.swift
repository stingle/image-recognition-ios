//
//  Face.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision

public class Face {

    public let image: UIImage
    private(set) public var pixelBuffer: [Float32]
    private(set) public var iteration: Int = 1

    internal init(image: UIImage, pixelBuffer: [Float32]) {
        self.image = image
        self.pixelBuffer = pixelBuffer
    }

    public func isSimilar(with face: Face) -> Bool {
        return self.pixelBuffer.computeCosineSimilarity(array: face.pixelBuffer) <= Constant.similarityThreshold
    }

    public func computeSimilarity(with face: Face) -> Float32 {
        return self.pixelBuffer.computeCosineSimilarity(array: face.pixelBuffer)
    }

    public func blend(face: Face) {
        let newIteration = self.iteration + 1
        if let buffer = self.pixelBuffer.blend(array: face.pixelBuffer, iteration: newIteration) {
            self.iteration = newIteration
            self.pixelBuffer = buffer
        }
    }

}

public extension Face {

    struct Constant {
        public static let similarityThreshold: Float32 = 0.4
    }

}
