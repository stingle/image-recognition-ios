//
//  AssetImageGenerator.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 11/15/21.
//

import Foundation
import AVFoundation

class AssetImageGenerator {

    func getFramesFromVideo(url: URL) -> [UIImage] { //todo right now I'm getting frames from every second, you can check it in for loop and also in generateThumnail function (preferredTimescale = 600). Checking every frame is painfull and super-slow, I can't imagine that someone will need it. For future - need to add functionality of comparing frames only by key pixels
        //        let framesNumber = getNumberOfFrames(url: url) //for test
        let asset = AVURLAsset(url: url)
        let durationInSeconds = asset.duration.seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        var frames = [UIImage]()
        for i in 0..<Int(durationInSeconds) {
            if let image = self.generateThumnail(url: url, fromTime: Float64(i)) {
                frames.append(image)
            }
        }

        return frames
    }

    private func generateThumnail(url : URL, fromTime: Float64) -> UIImage? {
        let asset :AVAsset = AVAsset(url: url)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero;
        let time : CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 600)
        if let img = try? assetImgGenerate.copyCGImage(at:time, actualTime: nil) {
            return UIImage(cgImage: img)
        } else {
            return nil
        }
    }

    /*
     func getNumberOfFrames(url: URL) -> Int {
     let asset = AVURLAsset(url: url, options: nil)
     do {
     let reader = try AVAssetReader(asset: asset)
     //AVAssetReader(asset: asset, error: nil)
     let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

     let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil) // NB: nil, should give you raw frames
     reader.add(readerOutput)
     reader.startReading()

     var nFrames = 0

     while true {
     let sampleBuffer = readerOutput.copyNextSampleBuffer()
     if sampleBuffer == nil {
     break
     }
     nFrames = nFrames+1
     }

     print("Num frames: \(nFrames)")
     return nFrames
     }catch {
     print("Error: \(error)")
     }
     return 0
     }
     */
}
