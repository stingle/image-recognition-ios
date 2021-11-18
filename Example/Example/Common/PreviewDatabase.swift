//
//  PreviewDatabase.swift
//  Example
//
//  Created by Shahen Antonyan on 11/9/21.
//

import Foundation
import UIKit
import ImageRecognition

class PreviewDatabase {

    static let shared = PreviewDatabase()

    private(set) var faces = [FaceObject]()
    private(set) var images = [(AnyObject, [FaceObject])]()

    private init() {}

    func addImages(images: [(AnyObject, [FaceObject])]) {
        self.images.append(contentsOf: images)
    }

    func addFaces(faces: [FaceObject]) {
        self.faces.append(contentsOf: faces)
    }

    func replaceFaces(faces: [FaceObject]) {
        self.faces = faces
    }
}
