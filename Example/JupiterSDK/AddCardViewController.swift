//
//  AddCardViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import Alamofire
import JupiterSDK

protocol AddCardDelegate {
    func sendCardItemData(data: [CardItemData])
    
    func sendPage(data: Int)
}

class AddCardViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var responseLabel: UILabel!
    
    var uuid: String = ""
    var code: String = ""
    var cardItemData: [CardItemData] = []
    
    var page: Int = 0

    var delegate : AddCardDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeTextField.delegate = self
        
//        guard let presentingVC = self.presentingViewController else { return }
    }

    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendCardItemData(data: cardItemData)
        self.delegate?.sendPage(data: page)
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
        codeTextField.resignFirstResponder()
        
        self.code = codeTextField.text ?? ""

        // Add Card
        let input = AddCard(user_id: uuid, sector_code: code)
        Network.shared.addCard(url: JUPITER_URL, input: input, completion: { [self]statusCode, returnedString in
            let addedCard = jsonToCard(json: returnedString)
            var message: String = addedCard.message
            if (message.count < 5) {
                message = jsonToFail(json: returnedString).message
            }
            switch (message) {
            case "Update Success":
                self.responseLabel.text = "\(addedCard.sector_name) 카드가 정상적으로 추가됐습니다"
                self.responseLabel.textColor = .systemBlue
                self.responseLabel.isHidden = false
                
                let id: Int = addedCard.sector_id
                let name: String = addedCard.sector_name
                let description: String = addedCard.description
                let cardColor: String = addedCard.cardColor
                let mode: Int = addedCard.mode
                let infoLevel: [String] = addedCard.infoLevel.components(separatedBy: " ")
                let infoBuilding: [String] = addedCard.infoBuilding.components(separatedBy: " ")
                
                self.cardItemData.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, infoLevel: infoLevel, infoBuilding: infoBuilding))
                
                self.page = self.page + 4
            case "Update Conflict":
                self.responseLabel.text = "이미 등록된 카드 입니다"
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            case "Update Fail":
                self.responseLabel.text = "유효한 코드를 입력해주세요 !!"
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            default:
                self.responseLabel.text = "유효한 코드를 입력해주세요 !!"
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            }
        })
    }
    
    func jsonToCard(json: String) -> AddCardSuccess {
        let result = AddCardSuccess(message: "", sector_id: 100, sector_name: "", description: "", cardColor: "", mode: 0, infoLevel: "", infoBuilding: "")
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(AddCardSuccess.self, from: data) {
            return decoded
        }

        return result
    }
    
    func jsonToFail(json: String) -> AddCardFail {
        let result = AddCardFail(message: "")
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(AddCardFail.self, from: data) {
            return decoded
        }

        return result
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeTextField.resignFirstResponder()
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
