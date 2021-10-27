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
        print(mediaType)
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
    
    func getFramesFromVideo(url: URL) -> [UIImage?] {//todo и подкрутить ручками и по умолчанию динамически
        //todo android model check
        let framesNumber = getNumberOfFrames(url: url)
        let asset = AVURLAsset(url: url)
        let durationInSeconds = asset.duration.seconds
        print("framesNumber = ", framesNumber)
        print("videoLength = ", durationInSeconds)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        var frames = [UIImage]()

        
        for i in 0..<Int(framesNumber) {
            if let cgImage = try? generator.copyCGImage(at: CMTime(seconds: Double(i), preferredTimescale: CMTimeScale(1)), actualTime: nil) {
                frames.append(UIImage(cgImage: cgImage))
            }
        }
        print("images.count = ", frames.count)
        
        return frames
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
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)
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
        let frames = getFramesFromVideo(url: videoURL)
        print("getFramesFromVideo = ", frames.count)//todo pdf
        self.didSelectFrames(frames: frames)
        self.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }

}
