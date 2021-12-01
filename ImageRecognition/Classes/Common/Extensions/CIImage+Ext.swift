//
//  CIImage+Ext.swift
//  ImageRecognition
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit

extension CIImage {

    func toUIImage() -> UIImage? {
        let context = CIContext()
        guard let cgImage: CGImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        let image: UIImage = UIImage(cgImage: cgImage)
        return image
    }

}
