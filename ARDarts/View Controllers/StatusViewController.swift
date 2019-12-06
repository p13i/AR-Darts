//
//  StatusViewController.swift
//  ARDarts
//
//  Created by Pramod Kotipalli on 7/7/18.
//  Copyright © 2018 Pramod Kotipalli. All rights reserved.
//

import Foundation
import UIKit

class StatusViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UIStatusLabel!
    
    enum Status: String {
        case searchingForWalls = "Searching for walls"
        case confirmingSelectedWall = "Confirming selected wall"
        case presentingCaptions = "Presenting captions"
        case error = "Error!"
    }
    
    private var currentStatus: Status? = nil
    public var status: Status {
        get {
            return currentStatus!
        }
        set(newStatus) {
            currentStatus = newStatus
            // Set the status label as well
            self.statusLabel.text = newStatus.rawValue
        }
    }
    
    override func viewDidLoad() {
        self.statusLabel.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
}
