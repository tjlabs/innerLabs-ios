import UIKit
import SwiftUI
import Alamofire
import Kingfisher
import JupiterSDK

struct AppFontName {
    static let bold = "NotoSansKR-Bold"
    static let medium = "NotoSansKR-Medium"
    static let regular = "NotoSansKR-Regular"
    static let light = "NotoSansKR-Light"
}

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var saveUuidButton: UIButton!
    
    var isSaveUuid: Bool = false
    var uuid: String = ""
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    
    let defaults = UserDefaults.standard
    
    let networkManager = Network()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = defaults.string(forKey: "uuid") {
            codeTextField.text = name
            saveUuidButton.isSelected.toggle()
            isSaveUuid = true
        }
        
        codeTextField.delegate = self
        
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        osVersion = Int(arr[0]) ?? 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func tapLoginButton(_ sender: UIButton) {
        self.uuid = codeTextField.text ?? ""
        
        if (uuid == "") {
            guideLabel.isHidden = false
        } else {
            if (isSaveUuid) {
                defaults.set(self.uuid, forKey: "uuid")
            } else {
                defaults.set(nil, forKey: "uuid")
            }
            defaults.synchronize()
            
            let login = Login(user_id: uuid, device_model: deviceModel, os_version: osVersion)
            postLogin(url: USER_URL, input: login)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeTextField.resignFirstResponder()
        
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func tapSaveUuidButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            isSaveUuid = true
        }
        else {
            isSaveUuid = false
        }
    }
    
    func postLogin(url: String, input: Login) {
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { [self] response in
            switch response.result {
            case .success(let res):
                do {
                    print("")
                    print("====================================")
                    print("응답 코드 :: ", response.response?.statusCode ?? 0)
                    print("-------------------------------")
                    print("응답 데이터 :: ", String(data: res, encoding: .utf8) ?? "")
                    print("====================================")
                    print("")
                    
                    let returnedString = String(decoding: response.data!, as: UTF8.self)
                    let list = jsonToCardList(json: returnedString)
                    let myCard = list.sectors
                    var reorderedCard = [CardInfo]()
                    
                    var cardDatas = [CardItemData]()
                    
                    if (myCard.isEmpty) {
                        print("최초 사용자 입니다")
                        cardDatas.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: "카드를 터치해주세요", cardColor: "purple", mode: "pdr", service: "NONE", infoBuilding: ["S3"], infoLevel: ["S3":["7F"]]))
                    } else {
                        print("최초 사용자가 아닙니다")
                        cardDatas.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: "카드를 터치해주세요", cardColor: "purple", mode: "pdr", service: "NONE", infoBuilding: ["S3"], infoLevel: ["S3":["7F"]]))
                        
                        print("Sector List :", myCard)
                        
                        KingfisherManager.shared.cache.clearMemoryCache()
                        KingfisherManager.shared.cache.clearDiskCache { print("Clear Cache Done !") }
                        
                        reorderedCard = myCard
                        
                        for card in 0..<reorderedCard.count {
                            let cardInfo: CardInfo = reorderedCard[card]
                            let id: Int = cardInfo.sector_id
                            let name: String = cardInfo.sector_name
                            let description: String = cardInfo.description
                            let cardColor: String = cardInfo.card_color
                            let mode: String = cardInfo.dead_reckoning
                            let service: String = cardInfo.service_request
                            let buildings_n_levels: [[String]] = cardInfo.building_level
                            
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
                                let urlSector = URL(string: "https://storage.googleapis.com/jupiter_image/card/\(id)/main_image.png")
                                let urlSectorShow = URL(string: "https://storage.googleapis.com/jupiter_image/card/\(id)/edit_image.png")
                                
                                let resourceSector = ImageResource(downloadURL: urlSector!, cacheKey: "\(id)Main")
                                let resourceSectorShow = ImageResource(downloadURL: urlSectorShow!, cacheKey: "\(id)Show")
                                
//                                KingfisherManager.shared.retrieveImage(with: resourceSector, completionHandler: nil)
//                                KingfisherManager.shared.retrieveImage(with: resourceSectorShow, completionHandler: nil)
                            }
                            
                            cardDatas.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, service: service, infoBuilding: infoBuilding, infoLevel: infoLevel))
                        }
                    }
                    
                    goToCardVC(cardDatas: cardDatas)
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                }
                break
            case .failure(let err):
                break
            }
        }
    }
    
    func goToCardVC(cardDatas: [CardItemData]) {
        guard let cardVC = self.storyboard?.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else { return }
        cardVC.uuid = uuid
        cardVC.cardItemData = cardDatas
        
        self.navigationController?.pushViewController(cardVC, animated: true)
        guideLabel.isHidden = true
    }
    func jsonToCardList(json: String) -> CardList {
        let result = CardList(sectors: [])

        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
            
            return decoded
        }
        
        return result
    }
    
    @objc func loginTapped() {
        self.uuid = codeTextField.text ?? ""
        
        if (uuid == "") {
            guideLabel.isHidden = false
        } else {
            if (isSaveUuid) {
                defaults.set(self.uuid, forKey: "uuid")
            } else {
                defaults.set(nil, forKey: "uuid")
            }
            defaults.synchronize()
            
            let login = Login(user_id: uuid, device_model: deviceModel, os_version: osVersion)
            postLogin(url: USER_URL, input: login)
        }
    }
}
