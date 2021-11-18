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
        self.openGallery(filter: .images)
    }

    func openVideoGallery() {
        self.openGallery(filter: .videos)
    }

    func didSelectLivePhoto(livePhoto: PHLivePhoto) {}

    func didSelectImage(image: UIImage) {}
    
    func didSelectVideo(videoURL: URL) {}

    func displayProgress(_ progress: Progress?) {}

    // MARK: - Private methods

    private func openGallery(filter: PHPickerFilter) {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.preferredAssetRepresentationMode = .current
        configuration.filter = filter
        let imagePickerController = PHPickerViewController(configuration: configuration)
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }

}

extension ImagePickerViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else {
            return
        }
        let progress: Progress?
        if result.itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
            progress = result.itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                guard let livePhoto = livePhoto as? PHLivePhoto else {
                    return
                }
                DispatchQueue.main.async {
                    self?.didSelectLivePhoto(livePhoto: livePhoto)
                }
            }
        } else if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            progress = result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let image = image as? UIImage else {
                    return
                }
                DispatchQueue.main.async {
                    self?.didSelectImage(image: image)
                }
            }
        } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            progress = result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                do {
                    guard let url = url, error == nil else {
                        return
                    }
                    let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try FileManager.default.removeItem(at: localURL)
                    try FileManager.default.copyItem(at: url, to: localURL)
                    DispatchQueue.main.async {
                        self?.didSelectVideo(videoURL: localURL)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
            progress = nil
        } else {
            progress = nil
        }
        self.displayProgress(progress)
    }

}
