//
//  AddCardViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher
import JupiterSDK

protocol AddCardDelegate {
    func sendCardItemData(data: [CardItemData])
    
    func sendPage(data: Int)
}

class AddCardViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var confirmLabel: UILabel!
    
    var uuid: String = ""
    var code: String = ""
    var cardItemData: [CardItemData] = []
    
    var page: Int = 0

    var delegate : AddCardDelegate?
    var currentRegion: String = ""
    var confirmText: String = ""
    var enrollSuccessText: String = ""
    var enrollConflictText: String = ""
    var enrollFailText: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locale = Locale.current
        if let countryCode = locale.regionCode, countryCode == "KR" {
            self.currentRegion = "Korea"
        } else {
            self.currentRegion = "Canada"
        }
        self.setTextByRegion(region: self.currentRegion)
        
        codeTextField.delegate = self
    }
    
    func setTextByRegion(region: String) {
        switch (region) {
        case "Korea":
            self.confirmText = "완료"
            self.enrollSuccessText = " 카드가 등록 됐습니다"
            self.enrollConflictText = "이미 등록된 카드 입니다"
            self.enrollFailText = "유효한 코드를 입력해주세요"
        case "Canada":
            self.confirmText = "Confirm"
            self.enrollSuccessText = " card is enrolled"
            self.enrollConflictText = "Already enrolled card"
            self.enrollFailText = "Please enter the valid code"
        default:
            self.confirmText = "Confirm"
            self.enrollSuccessText = " card is enrolled"
            self.enrollConflictText = "Already enrolled card"
            self.enrollFailText = "Please enter the valid code"
        }
        
        self.confirmLabel.text = self.confirmText
    }

    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendCardItemData(data: cardItemData)
        self.delegate?.sendPage(data: page)
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
        codeTextField.resignFirstResponder()
        
        self.code = codeTextField.text ?? ""
        
        let locale = Locale.current
        var enrollMessage: String = ""
        // Add Card
        let input = AddCard(user_id: uuid, sector_code: code)
        Network.shared.addCard(url: USER_URL, input: input, completion: { [self] statusCode, returnedString in
            let addedCard = jsonToCard(json: returnedString)
            var message: String = addedCard.message
            if (message.count < 5) {
                message = jsonToFail(json: returnedString).message
            }
            
            switch (message) {
            case "Update Success":
                enrollMessage = "\(addedCard.sector_name)" + self.enrollSuccessText
                self.responseLabel.text = enrollMessage
                self.responseLabel.textColor = .systemBlue
                self.responseLabel.isHidden = false
                
                let id: Int = addedCard.sector_id
                let name: String = addedCard.sector_name
                let description: String = addedCard.description
                let cardColor: String = addedCard.card_color
                let mode: String = addedCard.dead_reckoning
                let service: String = addedCard.service_request
                let buildings_n_levels: [[String]] = addedCard.building_level
                
                var infoBuilding = [String]()
                var infoLevel = [String:[String]]()
                for building in 0..<buildings_n_levels.count {
                    let buildingName: String = buildings_n_levels[building][0]
                    let levelName: String = buildings_n_levels[building][1]
                    
                    // Building
                    if !(infoBuilding.contains(buildingName)) {
                        infoBuilding.append(buildingName)
                    }
                    
                    // Level
                    if let value = infoLevel[buildingName] {
                        var levels:[String] = value
                        levels.append(levelName)
                        infoLevel[buildingName] = levels
                    } else {
                        let levels:[String] = [levelName]
                        infoLevel[buildingName] = levels
                    }
                }
                
                if (id != 10) {
                    // KingFisher Image Download
                    let urlSector = URL(string: "https://storage.googleapis.com/\(IMAGE_URL)/card/\(id)/main_image.png")
                    let urlSectorShow = URL(string: "https://storage.googleapis.com/\(IMAGE_URL)/card/\(id)/edit_image.png")
                    
                    let resourceSector = ImageResource(downloadURL: urlSector!, cacheKey: "\(id)Main")
                    let resourceSectorShow = ImageResource(downloadURL: urlSectorShow!, cacheKey: "\(id)Show")
                    
                    KingfisherManager.shared.retrieveImage(with: resourceSector, completionHandler: nil)
                    KingfisherManager.shared.retrieveImage(with: resourceSectorShow, completionHandler: nil)
                }
                
                self.cardItemData.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, service: service, infoBuilding: infoBuilding, infoLevel: infoLevel))
                
                self.page = self.page + 4
            case "Update Conflict":
                enrollMessage = self.enrollConflictText
                self.responseLabel.text = enrollMessage
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            case "Update Fail":
                enrollMessage = self.enrollFailText
                self.responseLabel.text = enrollMessage
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            default:
                enrollMessage = self.enrollFailText
                self.responseLabel.text = enrollMessage
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            }
        })
    }
    
    func jsonToCard(json: String) -> AddCardSuccess {
        let result = AddCardSuccess(message: "", sector_id: 100, sector_name: "", description: "", card_color: "", dead_reckoning: "pdr", service_request: "", building_level: [[]])
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
