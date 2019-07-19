//
//  ViewController.swift
//  ClickableLabelDemo
//
//  Created by cubenoy22 on 2016/04/13.
//
//

import UIKit
import ClickableLabel

class ViewController: UIViewController {
    
    @IBOutlet weak var label: Label?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.label?.linkTapHandler = { link in
            UIApplication.shared.openURL(link)
        }
    }
}
