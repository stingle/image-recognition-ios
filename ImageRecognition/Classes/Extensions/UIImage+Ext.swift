//
//  UIImage+Ext.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit
import CoreML

public extension UIImage {

    func fixOrientation() -> UIImage? {
        UIGraphicsBeginImageContext(self.size)
        self.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    var cgImageOrientation: CGImagePropertyOrientation {
        switch self.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

}

extension UIImage {

    func getPixelData(buffer :inout [Double]){
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        //removes the alpha channel
        let n = 4
        let newCount = pixelData.count - pixelData.count/4
        buffer = (0..<newCount).map { Double(pixelData[$0 + $0/(n - 1)])}
    }

    func prewhiten(input :inout [Double], output :inout MLMultiArray){
        var sum :Double = Double(input.reduce(0, +))
        let mean :Double = sum / Double(input.count)

        sum = 0xF
        for i in 0..<input.count {
            input[i] = input[i] - mean
            sum += pow(input[i],2)
        }

        let std :Double = sqrt(sum/Double(input.count))
        let std_adj :Double = max(std, 1.0/sqrt(Double(input.count)))

        var  i = 0
        for value in input{
            output[i] = NSNumber(value: Float32(value/std_adj))
            i += 1
        }
    }

    func resized(size: CGSize = CGSize(width: 160.0, height: 160.0)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), true, 3.0)
        self.draw(in: CGRect(x:0, y:0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

}
