//
//  AssetImageGenerator.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/15/21.
//

import Foundation
import AVFoundation
import Photos
import UIKit

public class AssetImageGenerator {

    private var maximumDurationOfPredictionsForVideo = 5000.0 // in milliseconds
    private var lastVideoMomentDetected = 0.0

    private (set) var frameDetectionStartedForFace: Double = 0.0
    private var faceDetectionStarted: Double = 0.0

    private var videoAsset: AVAsset!

    var oneFramePredictionTime: Double = 0.0

    public init() {}

    public func generateThumnail(videoAsset: AVAsset, fromTime: Float64) throws -> UIImage? {
        let assetImgGenerate: AVAssetImageGenerator = AVAssetImageGenerator(asset: videoAsset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero
        let time: CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 600)
        let img = try assetImgGenerate.copyCGImage(at:time, actualTime: nil)
        return UIImage(cgImage: img)
    }

    public func generateThumnail(videoURL: URL, fromTime: Float64) throws -> UIImage? {
        let asset = AVAsset(url: videoURL)
        return try self.generateThumnail(videoAsset: asset, fromTime: fromTime)
    }

    // MARK: - Internal methods

    func configure(asset: AVAsset, configuration: Configuration) {
        self.videoAsset = asset
        self.faceDetectionStarted = Date().timeIntervalSince1970 * 1000
        self.frameDetectionStartedForFace = Date().timeIntervalSince1970 * 1000

        let duration = self.videoAsset?.duration.seconds ?? 0.0
        self.lastVideoMomentDetected = min(duration, configuration.startTime)
        self.maximumDurationOfPredictionsForVideo = configuration.maxProcessingDuration
    }

    func getImagesFromLivePhoto(livePhoto: PHLivePhoto, completion: @escaping ([UIImage]) -> Void) {
        let assetResource = PHAssetResource.assetResources(for: livePhoto)
        var images = [UIImage]()
        var count = assetResource.count
        for assetResource in assetResource {
            PHAssetResourceManager.default().requestData(for: assetResource, options: nil) { data in
                guard let image = UIImage(data: data) else {
                    return
                }
                images.append(image)
            } completionHandler: { error in
                count -= 1
                if count == 0 {
                    completion(images)
                }
            }
        }
    }

    func getImagesFromGIF(url: URL) -> [UIImage] {
        let images = UIImage.gif(url: url)
        return images?.images ?? []
    }

    func faceDetectionFromSource() throws -> UIImage? {
        guard self.videoAsset != nil else {
            return nil
        }
        let frameDetectionStarted = Date().timeIntervalSince1970 * 1000
        let alreadySpentOnDetection = frameDetectionStarted - self.faceDetectionStarted
        let timeLeftForDetection = self.maximumDurationOfPredictionsForVideo - alreadySpentOnDetection
        let framesCanGet = timeLeftForDetection / self.oneFramePredictionTime
        let durationInSeconds = self.videoAsset.duration.seconds
        let leftToCheckVideoDutaion = durationInSeconds - self.lastVideoMomentDetected
        let stepForFrame = leftToCheckVideoDutaion / Double(framesCanGet)
        if timeLeftForDetection > self.oneFramePredictionTime && (self.lastVideoMomentDetected + stepForFrame) < durationInSeconds {
            self.frameDetectionStartedForFace = frameDetectionStarted
            self.lastVideoMomentDetected += stepForFrame
            return try self.generateThumnail(videoAsset: self.videoAsset, fromTime: self.lastVideoMomentDetected)
        } else {
            return nil
        }
    }

}
