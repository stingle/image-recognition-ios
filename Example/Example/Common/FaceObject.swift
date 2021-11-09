//
//  FaceObject.swift
//  Example
//
//  Created by Shahen Antonyan on 11/9/21.
//

import Foundation
import ImageRecognition

class FaceObject {
    var face: Face
    var bounds: CGRect

    init(face: Face, bounds: CGRect) {
        self.face = face
        self.bounds = bounds
    }
}

extension FaceObject: Hashable {

    static func == (lhs: FaceObject, rhs: FaceObject) -> Bool {
        return lhs.face.isSimilar(with: rhs.face)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.face.pixelBuffer)
    }

}
