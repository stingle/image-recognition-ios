//
//  FaceDetector.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision

public class FaceDetector {

    public init() {}

    public func detectFace(from image: UIImage, completion: @escaping (Result<[Face], FaceDetectorError>) -> Void) {
        guard let image = image.fixOrientation(), let ciImage = CIImage(image: image) else {
            completion(.failure(.badImage))
            return
        }
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            var detectedFaces = [Face]()
            for face in faces {
                let bounds = VNImageRectForNormalizedRect(face.boundingBox, Int(image.size.width), Int(image.size.height))
                let croppedImage = ciImage.cropped(to: bounds)
                guard let featurePrint = self.featurePrintObservationForImage(ciImage: croppedImage) else {
                    continue
                }
                guard let newImage = croppedImage.toUIImage() else {
                    continue
                }
                detectedFaces.append(Face(boundingBox: face.boundingBox, image: newImage, features: FaceFeatures(featurePrint: featurePrint)))
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

    public func compute(faceFeatures: FaceFeatures, image: UIImage, completion: @escaping (Result<(face: Face, percent: Float)?, FaceDetectorError>) -> Void) {
        self.detectFace(from: image) { result in
            switch result {
            case .success(let faces):
                var results = [(face: Face, percent: Float)]()
                do {
                    for face in faces {
                        var distance = Float(0)
                        try faceFeatures.featurePrint.computeDistance(&distance, to: face.features.featurePrint)
                        let percent = 100 - min(100, distance)
                        results.append((face, percent))
                    }
                } catch {}
                guard !results.isEmpty else {
                    completion(.success(nil))
                    return
                }
                results.sort(by: { $0.percent > $1.percent })
                completion(.success((results.first!.face, results.first!.percent)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func compute(faceFeatures: FaceFeatures, images: [UIImage], progress: @escaping (Float) -> Void, completion: @escaping (Result<[UIImage], FaceDetectorError>) -> Void) {
        guard !images.isEmpty else {
            completion(.success([]))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var count = images.count
            var results = [UIImage]()
            for image in images {
                self.compute(faceFeatures: faceFeatures, image: image) { result in
                    switch result {
                    case .success(let computeResult):
                        if let computeResult = computeResult, computeResult.percent > 90.0 {
                            results.append(image)
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
    }

    // MARK: - Private methods

    private func featurePrintObservationForImage(ciImage: CIImage) -> VNFeaturePrintObservation? {
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()
        do {
            try requestHandler.perform([request])
            return request.results?.first
        } catch {
            print("Vision error: \(error)")
            return nil
        }
    }

}
