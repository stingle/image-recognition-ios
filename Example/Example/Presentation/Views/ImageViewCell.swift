//
//  ImageViewCell.swift
//  Example
//
//  Created by Shahen Antonyan on 10/27/21.
//

import UIKit

class ImageViewCell: UICollectionViewCell {
    @IBOutlet weak private var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.contentMode = .scaleAspectFit
    }

    var circle: Bool = false {
        didSet {
            self.imageView.layer.cornerRadius = self.circle ? self.imageView.frame.width / 2 : 0.0
        }
    }

    var image: UIImage? {
        get {
            return self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }
}
