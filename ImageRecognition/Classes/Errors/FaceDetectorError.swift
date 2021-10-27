//
//  FaceDetectorError.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import Foundation

public class FaceDetectorError: LocalizedError {
    enum ErrorType: Int {
        case badImage = 0
        case failed
    }

    private var type: ErrorType

    public var errorDescription: String? {
        switch self.type {
        case .badImage:
            return "Wrong image"
        case .failed:
            return "Failed to find faces"
        }
    }

    init(type: ErrorType) {
        self.type = type
    }

    static var badImage: FaceDetectorError {
        return FaceDetectorError(type: .badImage)
    }

    static var failed: FaceDetectorError {
        return FaceDetectorError(type: .failed)
    }

}
