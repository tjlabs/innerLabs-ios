//
//  RegisterViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/08/08.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import TextFieldEffects

class RegisterViewController: UIViewController {
    
    let backButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeUI()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func makeUI() {
        
    }
    
}
