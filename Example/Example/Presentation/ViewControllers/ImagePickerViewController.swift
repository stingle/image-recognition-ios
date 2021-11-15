//
//  UIViewController+PhotoPicker.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 18.10.21.
//

import PhotosUI
import CoreServices

class ImagePickerViewController: UIViewController {

    func openPhotoGallery() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }

    func openVideoGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }

    func didSelectImage(image: UIImage) {}
    
    func didSelectVideo(videoURL: URL) {}

    // MARK: - Private methods

    private func imageSelected(info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        self.didSelectImage(image: tempImage)
        self.dismiss(animated: true)
    }

    private func videoSelected(info: [UIImagePickerController.InfoKey : Any]) {
        let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        self.didSelectVideo(videoURL: videoURL)
        self.dismiss(animated: true)
    }

}

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard info[UIImagePickerController.InfoKey.mediaType] != nil else { return }
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        switch mediaType {
        case kUTTypeImage:
            self.imageSelected(info: info)
        case kUTTypeMovie:
            self.videoSelected(info: info)
        case kUTTypeLivePhoto:
            print("live photo")
        default: break
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }

}
