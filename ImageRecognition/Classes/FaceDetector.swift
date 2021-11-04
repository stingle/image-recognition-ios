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
        static let embeddingsSize: Int = 512
        static let inputSizeHeight: Int = 160
        static let inputSizeWidth: Int = 160
    }

    private let facenet: Facenet6
    private var rgbValues: [Double]
    private var inputBuffer: MLMultiArray


    public init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.facenet = try Facenet6(configuration: config)
            //models' buffers allocation
            self.inputBuffer = try MLMultiArray(shape: [1, NSNumber(value: Constants.inputSizeHeight), NSNumber(value: Constants.inputSizeWidth), 3], dataType: MLMultiArrayDataType.float32)
            self.rgbValues = Array(repeating: 0.0, count: Constants.inputSizeWidth * Constants.inputSizeHeight * 3)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public func detectFaces(from image: UIImage, completion: @escaping (Result<[Face], FaceDetectorError>) -> Void) {
        self.visionDetectFace(from: image, completion: completion)
    }

    public func computeSimilarity(face: Face, with otherFace: Face) -> Float32 {
        let similarity = self.cosineSim(A: face.pixelBuffer, B: otherFace.pixelBuffer)
        return similarity
    }

    public func computeSimilarity(face: Face, with faces: [Face]) -> [Face: Float32] {
        var similarities = [Face: Float32]()
        for face in faces {
            let similarity = self.cosineSim(A: face.pixelBuffer, B: face.pixelBuffer)
            similarities[face] = similarity
        }
        return similarities
    }

    public func compute(face: Face, image: UIImage, completion: @escaping (Result<(Face, Float32)?, FaceDetectorError>) -> Void) {
        self.detectFaces(from: image) { result in
            switch result {
            case .success(let faces):
                var results = [(face: Face, similarity: Float32)]()
                for _face in faces {
                    let similarity = self.cosineSim(A: face.pixelBuffer, B: _face.pixelBuffer)
                    guard similarity >= 0.6 else { continue }
                    results.append((_face, similarity))
                }
                guard !results.isEmpty else {
                    completion(.success(nil))
                    return
                }
                results.sort(by: { $0.1 > $1.1 })
                completion(.success(results.first!))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func compute(face: Face, images: [UIImage], progress: @escaping (Float) -> Void, completion: @escaping (Result<[(UIImage, Face, Float32)], FaceDetectorError>) -> Void) {
        guard !images.isEmpty else {
            completion(.success([]))
            return
        }
        var count = images.count
        var results = [(UIImage, Face, Float32)]()
        for image in images {
            self.compute(face: face, image: image) { result in
                switch result {
                case .success(let computeResult):
                    if let computeResult = computeResult {
                        results.append((image, computeResult.0, computeResult.1))
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
        let pixelArray = try self.recognize(image: newImage.resized())
        return Face(boundingBox: bounds, image: newImage.resized(), pixelBuffer: pixelArray)
    }

    private func ciDetectFace(from image: UIImage, completion: @escaping (Result<[Face], FaceDetectorError>) -> Void) {
        guard let image = image.fixOrientation(), let ciImage = CIImage(image: image) else {
            completion(.failure(.badImage))
            return
        }
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: options) else {
            completion(.failure(.failed))
            return
        }
        var detectedFaces = [Face]()
        let opts = [CIDetectorImageOrientation: String(CGImagePropertyOrientation(image.imageOrientation).rawValue)]
        let features = detector.features(in: ciImage, options: opts)
        for feature in features {
            var bounds = feature.bounds
            if bounds.width > bounds.height {
                bounds.origin.y -= (bounds.width - bounds.height) / 2
                bounds.size.height = bounds.width
            } else if bounds.height > bounds.width {
                bounds.origin.x -= (bounds.height - bounds.width) / 2
                bounds.size.width = bounds.height
            }
            do {
                let face = try self.face(from: ciImage, bounds: bounds)
                detectedFaces.append(face)
            } catch {
                completion(.failure(.failed))
            }
        }
        DispatchQueue.main.async {
            completion(.success(detectedFaces))
        }
    }

    private func visionDetectFace(from image: UIImage, completion: @escaping (Result<[Face], FaceDetectorError>) -> Void) {
        guard let image = image.fixOrientation(), let ciImage = CIImage(image: image) else {
            completion(.failure(.badImage))
            return
        }
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            var detectedFaces = [Face]()
            for face in faces {
                var bounds = VNImageRectForNormalizedRect(face.boundingBox, Int(image.size.width), Int(image.size.height))
                if bounds.width > bounds.height {
                    bounds.origin.y = bounds.height / bounds.width * bounds.origin.y
                } else if bounds.height > bounds.width {
                    bounds.origin.x = bounds.width / bounds.height * bounds.origin.x
                }
                do {
                    guard let face = try self?.face(from: ciImage, bounds: bounds) else {
                        return
                    }
                    detectedFaces.append(face)
                } catch {
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

    private func dot(A: [Float32], B: [Float32]) -> Float32 {
        var x: Float32 = 0
        for i in 0...A.count-1 {
            x += A[i] * B[i]
        }
        return x
    }

    private func magnitude(A: [Float32]) -> Float32 {
        var x: Float32 = 0
        for elt in A {
            x += elt * elt
        }
        return sqrt(x)
    }

    private func cosineSim(A: [Float32], B: [Float32]) -> Float32 {
        return self.dot(A: A, B: B) / (self.magnitude(A: A) * self.magnitude(A: B))
    }

}
