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

}

extension UIImage {

    func resized(size: CGSize = CGSize(width: 160.0, height: 160.0)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), true, 3.0)
        self.draw(in: CGRect(x:0, y:0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

}

// GIF
extension UIImage {

    public class func animatedImageFromGIF(data: Data) -> UIImage? {
        return self.gif(data: data)?.animatedImage
    }

    public class func animatedImageFromGIF(url: URL) -> UIImage? {
        return self.gif(url: url)?.animatedImage
    }

    class func gif(data: Data) -> (images: [UIImage], animatedImage: UIImage?)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return UIImage.animatedImageWithSource(source)
    }

    class func gif(url: URL) -> (images: [UIImage], animatedImage: UIImage?)? {
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        return self.gif(data: imageData)
    }

    private class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        defer {
            gifPropertiesPointer.deallocate()
        }
        let unsafePointer = Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
        if CFDictionaryGetValueIfPresent(cfProperties, unsafePointer, gifPropertiesPointer) == false {
            return delay
        }
        let gifProperties: CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
        var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()), to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        if let delayObject = delayObject as? Double, delayObject > 0 {
            delay = delayObject
        } else {
            delay = 0.1
        }
        return delay
    }

    private class func gcdForPair(_ lhs: Int?, _ rhs: Int?) -> Int {
        var lhs = lhs
        var rhs = rhs
        if rhs == nil || lhs == nil {
            if rhs != nil {
                return rhs!
            } else if lhs != nil {
                return lhs!
            } else {
                return 0
            }
        }
        if lhs! < rhs! {
            let ctp = lhs
            lhs = rhs
            rhs = ctp
        }
        var rest: Int
        while true {
            rest = lhs! % rhs!

            if rest == 0 {
                return rhs!
            } else {
                lhs = rhs
                rhs = rest
            }
        }
    }

    private class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }
        var gcd = array[0]
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        return gcd
    }

    private class func animatedImageWithSource(_ source: CGImageSource) -> (images: [UIImage], animatedImage: UIImage?) {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        for index in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, index, nil) {
                images.append(image)
            }
            let delaySeconds = UIImage.delayForImageAtIndex(Int(index), source: source)
            delays.append(Int(delaySeconds * 1000.0))
        }

        let duration: Int = {
            var sum = 0
            for val: Int in delays {
                sum += val
            }
            return sum
        }()

        let gcd = self.gcdForArray(delays)
        var frames = [UIImage]()
        var frame: UIImage
        var frameCount: Int
        for index in 0..<count {
            frame = UIImage(cgImage: images[Int(index)])
            frameCount = Int(delays[Int(index)] / gcd)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        let animation = UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
        return (frames, animation)
    }

}
