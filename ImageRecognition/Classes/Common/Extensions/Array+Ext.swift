//
//  Array+Ext.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/8/21.
//

import Foundation

extension Array where Element == Float32 {

    func computeCosineSimilarity(array: [Float32]) -> Float32 {
        guard self.count == array.count && !self.isEmpty else {
            return Float32.infinity
        }
        var dotProduct: Float32 = 0.0
        var vector1LengthSquared: Float32 = 0.0
        var vector2LengthSquared: Float32 = 0.0
        for i in 0..<self.count {
            dotProduct += self[i] * array[i]
            vector1LengthSquared += self[i] * self[i]
            vector2LengthSquared += array[i] * array[i]
        }
        return 1 - dotProduct / sqrt(vector1LengthSquared * vector2LengthSquared)
    }

    func computeEuclideanDistance(array: [Float32]) -> Float32 {
        guard self.count == array.count && !self.isEmpty else {
            return Float32.infinity
        }
        var sum: Float32 = 0.0
        for i in 0..<self.count {
            let diff = self[i] - array[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }

    func blend(array: [Float32], iteration: Int) -> [Float32]? {
        guard self.count == array.count && !self.isEmpty else {
            return nil
        }
        let f: Float32 = 1.0 / Float32(iteration)
        var result = Array(repeating: 0.0, count: self.count)
        for i in 0..<self.count {
            result[i] = self[i] * f + array[i] * (1 - f)
        }
        return result
    }

}
