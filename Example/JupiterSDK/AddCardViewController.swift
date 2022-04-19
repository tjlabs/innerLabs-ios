//
//  AddCardViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK

protocol AddCardDelegate {
    func sendCardItemData(data: [CardItemData])
}


class AddCardViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    
    var code: String = ""
    var cardItemData: [CardItemData] = []

    var delegate : AddCardDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeTextField.delegate = self
    }

    @IBAction func tapBackButton(_ sender: UIButton) {
        print("Tapped Back Button")
        
        self.delegate?.sendCardItemData(data: cardItemData)
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
        codeTextField.resignFirstResponder()
        
        self.code = codeTextField.text ?? ""
        
        if (checkValidCode(code: code)) {
            cardItemData.append(CardItemData(name: "Added Card", description: "카드를 터치해주세요", cardImage: "purpleCard", sectorImage: "sectorDefault", code: "purple", sectorID: 0, numZones: 3, order: 0))
            print("Card was added")
        } else {
            // Dialog
            print("Invalid Code !!")
        }
    }
    
    func checkValidCode(code: String) -> Bool {
        switch code {
        case "card1":
            return true
        case "card2":
            return true
        case "card3":
            return true
        case "card4":
            return true
        default:
            return false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeTextField.resignFirstResponder()
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
