//
//  FaceDetector.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import Vision
import Photos

public class FaceDetector {

    private var modelDataHandler: FacenetModelDataHandler?

    private let assetImageGenerator = AssetImageGenerator()

    private var dispatchQueue: DispatchQueue

    private var isDetectionInProgress = false

    public init(modelFileInfo: FileInfo = MobileNet.faceModelInfo, threadCount: Int = 4, queue: DispatchQueue? = nil) {
        self.dispatchQueue = queue ?? DispatchQueue.global(qos: .userInitiated)
        self.modelDataHandler = FacenetModelDataHandler(modelFileInfo: modelFileInfo)
    }

    public func detectFaces(fromImage image: UIImage, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.visionDetectFace(from: image, completion: completion)
    }

    private func removeDuplacatedFaces(faces: [(face: Face, bounds: CGRect)]) -> [(face: Face, bounds: CGRect)] {
        var uniqueFaces = [(face: Face, bounds: CGRect)]()
        for i in 0..<faces.count {
            var face1 = faces[i]
            uniqueFaces.append(face1)
            for j in (i + 1)..<faces.count {
                let face2 = faces[j]
                if face1.face.isSimilar(with: face2.face) {
                    face2.face.blend(face: face1.face)
                    uniqueFaces.removeLast()
                    uniqueFaces.append(face2)
                    face1 = face2
                }
            }
        }
        return uniqueFaces
    }

    public func detectFaces(fromVideo videoURL: URL, configuration: Configuration = Configuration(), completion: @escaping ([(face: Face, bounds: CGRect)]) -> Void) {
        self.dispatchQueue.async {
            guard !self.isDetectionInProgress else { return }
            self.isDetectionInProgress = true
            self.configureAssetGeneration(fromVideo: videoURL, configuration: configuration) {
                var results = [(face: Face, bounds: CGRect)]()
                self.detectFacesRecursively(fromVideo: videoURL) { images, isFinished in
                    if let images = images {
                        results.append(contentsOf: images)
                    }
                    if isFinished {
                        let uniqueFaces = self.removeDuplacatedFaces(faces: results)
                        self.isDetectionInProgress = !isFinished
                        completion(uniqueFaces)
                    }
                }
            }
        }
    }

    public func detectFaces(fromLivePhoto livePhoto: PHLivePhoto, maxProcessingImagesCount: Int = 5, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.dispatchQueue.async {
            guard !self.isDetectionInProgress else { return }
            self.isDetectionInProgress = true
            self.assetImageGenerator.getImagesFromLivePhoto(livePhoto: livePhoto) { images in
                guard !images.isEmpty else {
                    self.isDetectionInProgress = false
                    return
                }
                self.detectFaces(fromImages: images, maxProcessingImagesCount: maxProcessingImagesCount, completion: completion)
            }
        }
    }

    public func detectFaces(fromGIF gifURL: URL, maxProcessingImagesCount: Int = 5, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        self.dispatchQueue.async {
            guard !self.isDetectionInProgress else { return }
            self.isDetectionInProgress = true
            let images = self.assetImageGenerator.getImagesFromGIF(url: gifURL)
            guard !images.isEmpty else {
                self.isDetectionInProgress = false
                return
            }
            self.detectFaces(fromImages: images, maxProcessingImagesCount: maxProcessingImagesCount, completion: completion)
        }
    }

    // MARK: - Private methods

    private func configureAssetGeneration(fromVideo videoURL: URL, configuration: Configuration, completion: @escaping () -> Void) {
        self.assetImageGenerator.configure(videoURL: videoURL, configuration: configuration)
        if let image = try? self.assetImageGenerator.generateThumnail(url: videoURL, fromTime: 0.0) {
            self.visionDetectFace(from: image) { _ in
                let frameDetectionStarted = self.assetImageGenerator.frameDetectionStartedForFace
                let frameDetectionEnded = Date().timeIntervalSince1970 * 1000
                self.assetImageGenerator.oneFramePredictionTime = frameDetectionEnded - frameDetectionStarted
                completion()
            }
        } else {
            self.assetImageGenerator.oneFramePredictionTime = 720.0
            completion()
        }
    }

    private func detectFacesRecursively(fromVideo videoURL: URL, completion: @escaping ([(face: Face, bounds: CGRect)]?, Bool) -> Void) {
        do {
            if let image = try self.assetImageGenerator.faceDetectionFromSource(videoURL: videoURL) {
                self.visionDetectFace(from: image) { result in
                    let frameDetectionEnded = Date().timeIntervalSince1970 * 1000
                    self.assetImageGenerator.oneFramePredictionTime = frameDetectionEnded - self.assetImageGenerator.frameDetectionStartedForFace
                    switch result {
                    case .success(let value):
                        completion(value, false)
                        self.detectFacesRecursively(fromVideo: videoURL, completion: completion)
                    case .failure(_):
                        completion(nil, false)
                        self.detectFacesRecursively(fromVideo: videoURL, completion: completion)
                    }
                }
            } else {
                completion(nil, true)
            }
        } catch {
            self.detectFacesRecursively(fromVideo: videoURL, completion: completion)
        }
    }

    private func detectFaces(fromImages: [UIImage], maxProcessingImagesCount: Int, completion: @escaping (Result<[(face: Face, bounds: CGRect)], FaceDetectorError>) -> Void) {
        var results = [(face: Face, bounds: CGRect)]()
        self.detectFacesRecursively(fromImages: fromImages, maxProcessingImagesCount: maxProcessingImagesCount, nextIndex: 0) { faces, isFinished in
            results.append(contentsOf: faces)
            if isFinished {
                let uniqueFaces = self.removeDuplacatedFaces(faces: results)
                self.isDetectionInProgress = !isFinished
                completion(.success(uniqueFaces))
            }
        }
    }

    private func detectFacesRecursively(fromImages: [UIImage], maxProcessingImagesCount: Int, nextIndex: Int, completion: @escaping ([(face: Face, bounds: CGRect)], Bool) -> Void) {
        guard fromImages.count > nextIndex else {
            completion([], true)
            return
        }
        let image = fromImages[nextIndex]
        self.visionDetectFace(from: image) { result in
            switch result {
            case .success(let value):
                completion(value, false)
            case .failure(_): break
            }
            let step = fromImages.count / min(maxProcessingImagesCount, fromImages.count)
            let index = nextIndex + step
            self.detectFacesRecursively(fromImages: fromImages, maxProcessingImagesCount: maxProcessingImagesCount, nextIndex: index, completion: completion)
        }
    }

    private func recognize(image: UIImage) throws -> [Float32] {
        guard let pixelBuffer = CVPixelBuffer.pixelBuffer(from: image) else {
            return []
        }
        let result = self.modelDataHandler?.runModel(onFrame: pixelBuffer)
        return result ?? []
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
        let request = VNDetectFaceCaptureQualityRequest { [weak self] request, error in
            guard let faces = request.results as? [VNFaceObservation] else { return }
            var detectedFaces = [(Face, CGRect)]()
            for face in faces {
                guard face.faceCaptureQuality ?? 0.0 >= 0.22 else { continue }
                do {
                    let rect = VNImageRectForNormalizedRect(face.boundingBox, Int(image.size.width), Int(image.size.height))
                    guard let face = try self?.face(from: ciImage, bounds: rect) else {
                        return
                    }
                    var boundingBox = CGRect(x: rect.origin.x / image.size.width, y: rect.origin.y / image.size.height, width: rect.width / image.size.width, height: rect.height / image.size.height)
                    boundingBox.origin.y = 1 - boundingBox.maxY
                    detectedFaces.append((face, boundingBox))
                } catch {
                    completion(.failure(.failed))
                }
            }
            completion(.success(detectedFaces))
        }
        self.dispatchQueue.async {
            do {
                try VNSequenceRequestHandler().perform([request], on: ciImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
            } catch {
                completion(.failure(.failed))
            }
        }
    }
}
