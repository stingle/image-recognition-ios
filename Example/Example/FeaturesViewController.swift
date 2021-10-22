//
//  FeaturesViewController.swift
//  Example
//
//  Created by Shahen Antonyan on 10/22/21.
//

import UIKit

enum Feature: Int, CaseIterable {
    case objectDetection = 0
    case faceDetection

    var title: String {
        switch self {
            case .objectDetection:
                return "Object Detection"
            case .faceDetection:
                return "Face Detection"
        }
    }
}

class FeaturesViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Features"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.tableView.tableFooterView = UIView()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Feature.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        let feature = Feature(rawValue: indexPath.row)!
        cell.textLabel?.text = feature.title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feature = Feature(rawValue: indexPath.row)!
        switch feature {
            case .objectDetection:
                self.performSegue(withIdentifier: "showObjectDetection", sender: self)
            case .faceDetection:
                self.performSegue(withIdentifier: "showFaceDetection", sender: self)
        }
    }

}
