//
//  FaceDetector.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision

public class FaceDetector {

    private struct Constants {
        static let inputSizeHeight: Int = 160
        static let inputSizeWidth: Int = 160
    }

    private let facenet: Facenet
    private var rgbValues: [Double]
    private var inputBuffer: MLMultiArray

    public init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.facenet = try Facenet(configuration: config)
            self.inputBuffer = try MLMultiArray(shape: [1, NSNumber(value: Constants.inputSizeHeight), NSNumber(value: Constants.inputSizeWidth), 3], dataType: MLMultiArrayDataType.float32)
            self.rgbValues = Array(repeating: 0.0, count: Constants.inputSizeWidth * Constants.inputSizeHeight * 3)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public func detectFaces(from image: UIImage, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.visionDetectFace(from: image, completion: completion)
    }

    public func recognize(face: Face, image: UIImage, completion: @escaping (Result<(face: Face, bounds: CGRect)?, FaceDetectorError>) -> Void) {
        self.detectFaces(from: image) { result in
            switch result {
            case .success(let faces):
                var previousSimilarity = Float32.infinity
                var closestFace: (Face, CGRect)?
                for _face in faces {
                    let similarity = face.computeSimilarity(with: _face.face)
                    if similarity <= Face.Constant.similarityThreshold && similarity < previousSimilarity {
                        closestFace = _face
                        previousSimilarity = similarity
                    }
                }
                completion(.success(closestFace))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func recognize(face: Face, images: [UIImage], progress: @escaping (Float) -> Void, completion: @escaping (Result<[(image: UIImage, face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        guard !images.isEmpty else {
            completion(.success([]))
            return
        }
        var count = images.count
        var results = [(UIImage, Face, CGRect)]()
        for image in images {
            self.recognize(face: face, image: image) { result in
                switch result {
                case .success(let recognizedFace):
                    if let recognizedFace = recognizedFace {
                        results.append((image, recognizedFace.face, recognizedFace.bounds))
                    }
                    count -= 1
                case .failure(_):
                    count -= 1
                }
                if count == 0 {
                    progress(100.0)
                    completion(.success(results))
                } else {
                    let percent = Float(images.count - count) / Float(images.count) * 100.0
                    progress(percent)
                }
            }
        }
    }

    // MARK: - Private methods

    private func recognize(image: UIImage) throws -> [Float32] {
        image.getPixelData(buffer: &self.rgbValues)
        image.prewhiten(input: &self.rgbValues, output: &self.inputBuffer)
        let prediction = try self.facenet.prediction(input: self.inputBuffer)
        let b = try UnsafeBufferPointer<Float32>(prediction.embeddings)
        return Array(b)
    }

    private func face(from ciImage: CIImage, bounds: CGRect) throws -> Face {
        let croppedImage = ciImage.cropped(to: bounds)
        guard let newImage = croppedImage.toUIImage() else {
            throw FaceDetectorError.failed
        }
        let resized = newImage.resized()
        let pixelArray = try self.recognize(image: resized)
        return Face(image: resized, pixelBuffer: pixelArray)
    }

    private func visionDetectFace(from image: UIImage, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        guard let image = image.fixOrientation(), let ciImage = CIImage(image: image) else {
            completion(.failure(.badImage))
            return
        }
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            var detectedFaces = [(Face, CGRect)]()
            for face in faces {
                let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(image.size.width), Int(image.size.height))
                do {
                    guard let face = try self?.face(from: ciImage, bounds: rect) else {
                        return
                    }
                    var boundingBox = CGRect(x: rect.origin.x / image.size.width, y: rect.origin.y / image.size.height, width: rect.width / image.size.width, height: rect.height / image.size.height)
                    boundingBox.origin.y = 1 - boundingBox.maxY
                    detectedFaces.append((face, boundingBox))
                } catch {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        completion(.failure(.failed))
                    }
                }
            }
            DispatchQueue.main.async {
                completion(.success(detectedFaces))
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try VNSequenceRequestHandler().perform([request], on: ciImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
            } catch {
                completion(.failure(.failed))
            }
        }
    }

}
