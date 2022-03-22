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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
        JupiterTest().callLib()
        
        guard let jupiterVC = self.storyboard?.instantiateViewController(withIdentifier: "JupiterViewController") else { return }
        self.navigationController?.pushViewController(jupiterVC, animated: true)
    }
    
}

