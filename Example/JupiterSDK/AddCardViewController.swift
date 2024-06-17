
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
        var addCardUrl = USER_URL
        var imageUrl = "https://storage.googleapis.com/\(IMAGE_URL)"
        if (IS_OLYMPUS) {
            addCardUrl = USER_CARD_URL
            imageUrl = USER_IMAGE_URL
        }
        Network.shared.addCard(url: addCardUrl, input: input, completion: { [self] statusCode, returnedString in
            var addedCard = AddCardSuccess(message: "", sector_id: -1, sector_name: "", description: "", card_color: "", dead_reckoning: "", service_request: "", building_level: [[]])
            if (IS_OLYMPUS) {
                let addCardOlympus: AddCardOlympus = jsonToOlympusCard(json: returnedString)
                addedCard.message = addCardOlympus.message
                addedCard.sector_id = addCardOlympus.sector.sector_id
                addedCard.sector_name = addCardOlympus.sector.sector_name
                addedCard.description = addCardOlympus.sector.description
                addedCard.card_color = addCardOlympus.sector.card_color
                addedCard.dead_reckoning = addCardOlympus.sector.dead_reckoning
                addedCard.service_request = addCardOlympus.sector.service_request
                addedCard.building_level = addCardOlympus.sector.building_level
            } else {
                let addCardSuccess: AddCardSuccess = jsonToCard(json: returnedString)
                addedCard = addCardSuccess
            }

            var message: String = addedCard.message
            if (message.count < 5) {
                message = jsonToFail(json: returnedString).message
            }
            
            if (message.contains("Success")) {
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
                
                if (IS_OLYMPUS) {
                    if (id != 1) {
                        // KingFisher Image Download
                        let urlSector = URL(string: "\(imageUrl)/card/\(id)/main.png")
                        let urlSectorShow = URL(string: "\(imageUrl)/card/\(id)/edit.png")
                        
                        KingfisherManager.shared.retrieveImage(with: urlSector!, completionHandler: nil)
                        KingfisherManager.shared.retrieveImage(with: urlSectorShow!, completionHandler: nil)
                    }
                } else {
                    if (id != 10) {
                        // KingFisher Image Download
                        let urlSector = URL(string: "\(imageUrl)/card/\(id)/main_image.png")
                        let urlSectorShow = URL(string: "\(imageUrl)/card/\(id)/edit_image.png")
                        
                        KingfisherManager.shared.retrieveImage(with: urlSector!, completionHandler: nil)
                        KingfisherManager.shared.retrieveImage(with: urlSectorShow!, completionHandler: nil)
                    }
                }
                
                
                self.cardItemData.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, service: service, infoBuilding: infoBuilding, infoLevel: infoLevel))
                
                self.page = self.page + 4
            } else if (message.contains("Conflict")) {
                enrollMessage = self.enrollConflictText
                self.responseLabel.text = enrollMessage
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            } else if (message.contains("Fail")){
                enrollMessage = self.enrollFailText
                self.responseLabel.text = enrollMessage
                self.responseLabel.textColor = .systemRed
                self.responseLabel.isHidden = false
            } else {
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
    
    func jsonToOlympusCard(json: String) -> AddCardOlympus {
        let result = AddCardOlympus(message: "", sector: CardInfo(sector_id: 100, sector_name: "", description: "", card_color: "", dead_reckoning: "pdr", service_request: "", building_level: [[]]))
        let decoder = JSONDecoder()
        let jsonString = json
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(AddCardOlympus.self, from: data) {
            return decoded
        }
        return result
    }
    
//    func jsonToCard(json: String, isOlympus: Bool) -> AddCardSuccess {
//        let result = AddCardSuccess(message: "", sector_id: 100, sector_name: "", description: "", card_color: "", dead_reckoning: "pdr", service_request: "", building_level: [[]])
//        let decoder = JSONDecoder()
//        
//        print("Check (0) : \(json)")
//        if isOlympus {
//            if let data = json.data(using: .utf8), let decoded = try? decoder.decode(AddCardSuccess.self, from: data) {
//                print("Check (1) : \(data)")
//                return decoded
//            } else {
//                print("Check (1) : Error")
//            }
//        } else {
//            // Do not use custom coding keys
//            if let data = json.data(using: .utf8), let decoded = try? decoder.decode(AddCardSuccessNoCustomKeys.self, from: data) {
//                print("Check (2) : \(data)")
//                return AddCardSuccess(message: decoded.message, sector_id: decoded.sector_id, sector_name: decoded.sector_name, description: decoded.description, card_color: decoded.card_color, dead_reckoning: decoded.dead_reckoning, service_request: decoded.service_request, building_level: decoded.building_level)
//            } else {
//                print("Check (2) : Error")
//            }
//        }
//
//        return result
//    }
    
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
