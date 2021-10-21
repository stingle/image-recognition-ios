//
//  ViewController+PhotoPicker.swift
//  ImageRecognition
//
//  Created by Arthur Poghosyan on 18.10.21.
//

import PhotosUI

extension ViewController: UIImagePickerControllerDelegate {

     func presentPhotoPicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false 
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imageView.image  = tempImage
        self.userSelectedPhoto(imageView.image!)
        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
