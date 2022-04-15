//
//  CardViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class CardViewController: UIViewController {
    
    var uuid: String = ""
    
    // Card
    
//    let itemColors = [UIColor.red, UIColor.yellow, UIColor.blue, UIColor.green]
//    var currentIndex: CGFloat = 0
//    let lineSpacing: CGFloat = 20
//    let cellRatio: CGFloat = 0.7
//    var isOneStepPaging = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapShowCardButton(_ sender: UIButton) {
        guard let jupiterVC = self.storyboard?.instantiateViewController(withIdentifier: "JupiterViewController") as? JupiterViewController else { return }
        jupiterVC.uuid = uuid
        self.navigationController?.pushViewController(jupiterVC, animated: true)
    }
    
    
    @IBAction func tapAddCardButton(_ sender: UIButton) {
    }
    
}
