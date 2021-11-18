//
//  MobileNet.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/18/21.
//

import Foundation

/// Information about a model file or labels file.
public typealias FileInfo = (name: String, extension: String)

/// Information about the MobileNet model.
public enum MobileNet {
    static public let faceModelInfo: FileInfo = (name: "facenet", extension: "tflite")
    static public let objectModelInfo: FileInfo = (name: "objects", extension: "tflite")
    static public let objectsLabelsInfo: FileInfo = (name: "labels", extension: "txt")
}
