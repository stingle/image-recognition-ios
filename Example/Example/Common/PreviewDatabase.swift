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

    private(set) var faces = [(face: Face, bounds: CGRect)]()
    private(set) var images = [(UIImage, [(face: Face, bounds: CGRect)])]()

    private init() {}

    func addImages(images: [(UIImage, [(face: Face, bounds: CGRect)])]) {
        self.images.append(contentsOf: images)
    }

    func addFaces(faces: [(face: Face, bounds: CGRect)]) {
        self.faces.append(contentsOf: faces)
    }

}
