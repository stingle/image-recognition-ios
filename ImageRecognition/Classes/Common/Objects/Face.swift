//
//  Face.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision

public class Face {

    public let identifier: String = UUID().uuidString
    public let image: UIImage

    private(set) public var pixelBuffer: [Float32]
    private(set) public var iteration: Int

    public var name: String?

    public init(image: UIImage, pixelBuffer: [Float32], iteration: Int = 1) {
        self.image = image
        self.pixelBuffer = pixelBuffer
        self.iteration = iteration
    }

    public func isSimilar(with face: Face, similarityThreshold: Float32 = Face.Constant.similarityThreshold) -> Bool {
        return self.pixelBuffer.computeCosineSimilarity(array: face.pixelBuffer) <= similarityThreshold
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
