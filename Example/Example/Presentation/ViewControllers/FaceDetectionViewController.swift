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

    private let database = PreviewDatabase.shared

    private var filteredImages: [(UIImage, [FaceObject])]?

    private var selectedFace: Face?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.facesCollectionView.allowsMultipleSelection = false
        self.imagesCollectionView.allowsMultipleSelection = false
        self.title = "Face Detection"
        self.filterAndPresentImages()
    }

    private func filterAndPresentImages() {
        guard let selectedFace = self.selectedFace else {
            self.filteredImages = self.database.images
            self.imagesCollectionView.reloadData()
            return
        }
        self.filteredImages = self.database.images.filter({ $0.1.contains(where: { selectedFace.isSimilar(with: $0.face) }) })
        self.imagesCollectionView.reloadData()
    }

    override func didSelectImage(image: UIImage) {
        self.selectedFace = nil
        self.collecteFaces(from: image)
    }

    private func collecteFaces(from image: UIImage) {
        self.faceDetector.detectFaces(from: image) {[ weak self] result in
            switch result {
            case .success(let newFaces):
                DispatchQueue.global().async {
                    let newFaceObjecs = newFaces.map({ FaceObject(face: $0.0, bounds: $0.1) })
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.database.addFaces(faces: newFaceObjecs)
                        self.database.addImages(images: [(image, newFaceObjecs)])
                        self.filteredImages = self.database.images
                        self.imagesCollectionView.reloadData()
                        DispatchQueue.global().async {
                            var uniqueFaces = [FaceObject]()
                            for i in 0..<self.database.faces.count {
                                let face1 = self.database.faces[i]
                                uniqueFaces.append(face1)
                                for j in (i + 1)..<self.database.faces.count {
                                    let face2 = self.database.faces[j]
                                    if face1.face.isSimilar(with: face2.face) {
                                        uniqueFaces.removeLast()
                                        break
                                    }
                                }
                            }
                            self.database.replaceFaces(faces: uniqueFaces)
                            DispatchQueue.main.async {
                                self.facesCollectionView.reloadData()
                            }
                        }
                    }
                }
            case .failure(let error):
                self?.database.addImages(images: [(image, [])])
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
            return self.database.faces.count
        }
        return self.filteredImages?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as! ImageViewCell
        if collectionView === self.facesCollectionView {
            let face = self.database.faces[indexPath.row]
            cell.image = face.face.image
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
                self.selectedFace = self.database.faces[indexPath.row].face
            } else {
                let face = self.database.faces[indexPath.row].face
                if face.isSimilar(with: self.selectedFace!) {
                    self.selectedFace = nil
                } else {
                    self.selectedFace = face
                }
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
