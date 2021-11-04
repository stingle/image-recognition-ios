//
//  UIViewController+PhotoPicker.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 18.10.21.
//

import PhotosUI
import MobileCoreServices

class ImagePickerViewController: UIViewController {

    func presentPhotoPicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }

    func didSelectImage(image: UIImage) {}
    
    func didSelectFrames(frames: [UIImage?]){}
    
    func openVideoGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }

}

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard info[UIImagePickerController.InfoKey.mediaType] != nil else { return }
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        switch mediaType {
        case kUTTypeImage:
            imageSelected(info: info)
            break
        case kUTTypeMovie:
            videoSelected(info: info)
            break
        case kUTTypeLivePhoto:
            print("live photo")
            break
        default:
            break
        }
        
    }
    
    func getFramesFromVideo(url: URL) -> [UIImage?] { //todo right now I'm getting frames from every second, you can check it in for loop and also in generateThumnail function (preferredTimescale = 600). Checking every frame is painfull and super-slow, I can't imagine that someone will need it. For future - need to add functionality of comparing frames only by key pixels
//        let framesNumber = getNumberOfFrames(url: url) //for test
        let asset = AVURLAsset(url: url)
        let durationInSeconds = asset.duration.seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        var frames = [UIImage]()
        for i in 0..<Int(durationInSeconds) {
            let cgImage = generateThumnail(url: url, fromTime: Float64(i))
            if cgImage != nil {
                frames.append(cgImage!)
            }
        }
        
        return frames
    }
    
    fileprivate func generateThumnail(url : URL, fromTime:Float64) -> UIImage? {
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
//            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)
            nFrames = nFrames+1
        }

        print("Num frames: \(nFrames)")
            return nFrames
        }catch {
            print("Error: \(error)")
        }
        return 0
    }
    
    // Convert CIImage to UIImage
    func convert(cmage: CIImage) -> UIImage {
         let context = CIContext(options: nil)
         let cgImage = context.createCGImage(cmage, from: cmage.extent)!
         let image = UIImage(cgImage: cgImage)
         return image
    }

    func imageSelected(info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        self.didSelectImage(image: tempImage)
        self.dismiss(animated: true)
    }
    
    func videoSelected(info: [UIImagePickerController.InfoKey : Any]) {
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        DispatchQueue.global(qos: .userInitiated).async {
            let frames = self.getFramesFromVideo(url: videoURL)//todo slowest function on Earth
            DispatchQueue.main.async {
                self.didSelectFrames(frames: frames)
                self.dismiss(animated: true)
            }
        }

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }

}
