//
//  FaceDetectionViewController.swift
//  Example
//
//  Created by Shahen Antonyan on 10/22/21.
//

import UIKit
import ARKit
import ImageRecognition

class FaceDetectionViewController: ImagePickerViewController {

    @IBOutlet weak var facesCollectionView: UICollectionView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!

    private let faceDetector = FaceDetector()

    private var faces = [Face]()
    private var images = [(UIImage, [Face])]()
    private var filteredImages: [(UIImage, [Face])]?

    private var selectedFace: Face?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.facesCollectionView.allowsMultipleSelection = false
        self.imagesCollectionView.allowsMultipleSelection = false
        self.title = "Face Detection"
    }

    private func filterAndPresentImages() {
        guard let selectedFace = self.selectedFace else {
            self.filteredImages = self.images
            self.imagesCollectionView.reloadData()
            return
        }
        self.filteredImages = self.images.filter({ $0.1.contains(where: { self.faceDetector.computeSimilarity(face: selectedFace, with: $0) >= 0.6 }) })
        self.imagesCollectionView.reloadData()
    }

    override func didSelectImage(image: UIImage) {
        self.selectedFace = nil
        self.collecteFaces(from: image)
    }

    private func collecteFaces(from image: UIImage) {
        self.faceDetector.detectFaces(from: image) {[ weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let newFaces):
                var existingFaces = self.faces
                DispatchQueue.global().async {
                    let filtered = newFaces.filter { face in
                        return !existingFaces.contains(where: { self.faceDetector.computeSimilarity(face: face, with: $0) >= 0.6 })
                    }
                    existingFaces.append(contentsOf: filtered)
                    DispatchQueue.main.async {
                        self.faces = existingFaces
                        self.images.append((image, newFaces))
                        self.filteredImages = self.images
                        self.facesCollectionView.reloadData()
                        self.imagesCollectionView.reloadData()
                    }
                }
            case .failure(let error):
                self.images.append((image, []))
                print(error.localizedDescription)
            }
        }
    }

    // MARK: - Actions

    @IBAction func addButtonAction(_ sender: Any) {
        self.presentPhotoPicker()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ImageViewController {
            if let selectedIndexPath = self.imagesCollectionView.indexPathsForSelectedItems?.first, let image = self.filteredImages?[selectedIndexPath.row] {
                viewController.image = image.0
                viewController.faces = image.1
                self.imagesCollectionView.deselectItem(at: selectedIndexPath, animated: true)
            }
        }
    }

}

extension FaceDetectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === self.facesCollectionView {
            return self.faces.count
        }
        return self.filteredImages?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as! ImageViewCell
        if collectionView === self.facesCollectionView {
            let face = self.faces[indexPath.row]
            cell.image = face.image
            cell.circle = true
        } else {
            let image = self.filteredImages![indexPath.row]
            cell.image = image.0
            cell.circle = false
        }
        return cell
    }

}

extension FaceDetectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === self.facesCollectionView {
            if self.selectedFace == nil {
                self.selectedFace = self.faces[indexPath.row]
            } else {
                self.selectedFace = nil
            }
            self.filterAndPresentImages()
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            self.performSegue(withIdentifier: "presentImage", sender: nil)
        }
    }

}

extension FaceDetectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === self.facesCollectionView {
            let height = collectionView.frame.height - 20.0
            return CGSize(width: height, height: height)
        }
        let width = (collectionView.frame.width - 30.0) / 2
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }

}
