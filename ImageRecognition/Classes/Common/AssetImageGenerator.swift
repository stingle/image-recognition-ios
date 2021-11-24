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

    public init() {}

    public func generateThumnail(url : URL, fromTime: Float64) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let assetImgGenerate: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero;
        let time: CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 600)
        if let img = try? assetImgGenerate.copyCGImage(at:time, actualTime: nil) {
            return UIImage(cgImage: img)
        } else {
            return nil
        }
    }

    func getFramesFromVideo(url: URL) -> [UIImage] {
        let asset = AVURLAsset(url: url)
        let durationInSeconds = asset.duration.seconds
        var frames = [UIImage]()
        for i in 0..<Int(durationInSeconds) {
            if let image = self.generateThumnail(url: url, fromTime: Float64(i)) {
                frames.append(image)
            }
        }
        return frames
    }
    
    func getFrameFromVideoForTime(url: URL, time: Float64) -> UIImage {
        let image = self.generateThumnail(url: url, fromTime: time)
        
        return image!
    }

    func getFrameFromSourceForTime(url: URL, time: Float64) -> UIImage {
        let image = self.generateThumnail(url: url, fromTime: time)
        
        return image!
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
}
