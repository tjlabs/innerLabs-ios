//
//  ViewController.swift
//  JupiterSDK
//
//  Created by Leo on 03/22/2022.
//  Copyright (c) 2022 Leo. All rights reserved.
//

import UIKit
import JupiterSDK

class MainViewController: UIViewController {
    
    @IBOutlet weak var codeTextField: UITextField!
//    @IBOutlet weak var guideLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
        let uuid: String = codeTextField.text ?? ""
        
        if (uuid == "") {
//            guideLabel.isHidden = false
        } else {
            guard let jupiterVC = self.storyboard?.instantiateViewController(withIdentifier: "JupiterViewController") as? JupiterViewController else { return }
            jupiterVC.uuid = uuid
            self.navigationController?.pushViewController(jupiterVC, animated: true)
//            guideLabel.isHidden = true
        }
        
    }
    
}

