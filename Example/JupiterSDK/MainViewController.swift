import UIKit
import SwiftUI
import Alamofire
import Kingfisher
import DropDown
import JupiterSDK

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var saveUuidButton: UIButton!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    var isSaveUuid: Bool = false
    var uuid: String = ""
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    var sdkVersion: String = ""
    
    let defaults = UserDefaults.standard
    
    let networkManager = Network()

    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var dropImage: UIImageView!
    @IBOutlet weak var dropText: UITextField!
    @IBOutlet weak var dropButton: UIButton!
    
    var regions: [String] = ["Korea", "Canada", "US(East)"]
    var currentRegion: String = "Korea"
    var defaultMeasage: String = ""
    
    let dropDown = DropDown()
    
//    var jupiterService = ServiceManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = defaults.string(forKey: "uuid") {
            codeTextField.text = name
            saveUuidButton.isSelected.toggle()
            isSaveUuid = true
        }
        
        codeTextField.delegate = self
        
        initDropDown()
        setDropDown()
        
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        osVersion = Int(arr[0]) ?? 0
        self.sdkVersion = ServiceManager.sdkVersion
        self.sdkVersionLabel.text = self.sdkVersion
        
        let locale = Locale.current
        if let countryCode = locale.regionCode, countryCode == "KR" {
            self.currentRegion = "Korea"
        } else {
            self.currentRegion = "Canada"
        }
        
        self.dropText.text = self.currentRegion
        setRegion(regionName: self.currentRegion)
        setServerURL(region: self.currentRegion)
        setDefaultMessage(region: self.currentRegion)
        
//        jupiterService.checkServiceAvailableDevice(completion: { statusCode, isUpdated, isAvailable in
//            print(getLocalTimeString() + " , (Jupiter) Information : isServiceAvailableDevice = \(statusCode) , \(isUpdated) , \(isAvailable)")
//        })
//        BlacklistChecker.shared.checkServiceAvailableDevice(completion: { statusCode, isUpdated, isAvailable in
//            print(getLocalTimeString() + " , (Jupiter) Information : isServiceAvailableDevice = \(statusCode) , \(isUpdated) , \(isAvailable)")
//        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func tapLoginButton(_ sender: UIButton) {
        self.uuid = codeTextField.text ?? ""
        
        if (uuid == "" || uuid.contains(" ")) {
            guideLabel.isHidden = false
        } else {
            if (isSaveUuid) {
                defaults.set(self.uuid, forKey: "uuid")
            } else {
                defaults.set(nil, forKey: "uuid")
            }
            defaults.synchronize()
            
            let login = Login(user_id: uuid, device_model: deviceModel, os_version: osVersion, sdk_version: sdkVersion)
            var loginUrl = LOGIN_URL
            if (IS_OLYMPUS) {
                loginUrl = USER_LOGIN_URL
            }
            self.loginButton.isEnabled = false
            postLogin(url: loginUrl, input: login)
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
                    print("Login URL :: ", url)
                    print("응답 코드 :: ", response.response?.statusCode ?? 0)
                    print("-------------------------------")
                    print("응답 데이터 :: ", String(data: res, encoding: .utf8) ?? "")
                    print("====================================")
                    print("")
                    
                    let returnedString = String(decoding: response.data!, as: UTF8.self)
                    let list = jsonToCardList(json: returnedString, isOlympus: IS_OLYMPUS)
                    let myCard = list.sectors
                    var reorderedCard = [CardInfo]()
                    
                    var cardDatas = [CardItemData]()
                    
                    if (myCard.isEmpty) {
                        print("최초 사용자 입니다")
                        cardDatas.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: self.defaultMeasage, cardColor: "purple", mode: "pdr", service: "NONE", infoBuilding: ["S3"], infoLevel: ["S3":["7F"]]))
                    } else {
                        print("최초 사용자가 아닙니다")
                        cardDatas.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: self.defaultMeasage, cardColor: "purple", mode: "pdr", service: "NONE", infoBuilding: ["S3"], infoLevel: ["S3":["7F"]]))
                        
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
                            
                            if (IS_OLYMPUS) {
                                if (id != 1) {
                                    let urlSector = URL(string: "\(USER_IMAGE_URL)/card/\(id)/main.png")
                                    let urlSectorShow = URL(string: "\(USER_IMAGE_URL)/card/\(id)/edit.png")
                                    
                                    KingfisherManager.shared.retrieveImage(with: urlSector!, completionHandler: nil)
                                    KingfisherManager.shared.retrieveImage(with: urlSectorShow!, completionHandler: nil)
                                }
                            } else {
                                if (id != 10) {
                                    // KingFisher Image Download
                                    let urlSector = URL(string: "https://storage.googleapis.com/" + IMAGE_URL + "/card/\(id)/main_image.png")
                                    let urlSectorShow = URL(string: "https://storage.googleapis.com/" + IMAGE_URL + "/card/\(id)/edit_image.png")
                                    
                                    KingfisherManager.shared.retrieveImage(with: urlSector!, completionHandler: nil)
                                    KingfisherManager.shared.retrieveImage(with: urlSectorShow!, completionHandler: nil)
                                }
                            }
                            
                            cardDatas.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, service: service, infoBuilding: infoBuilding, infoLevel: infoLevel))
                        }
                    }
                    
                    self.loginButton.isEnabled = true
                    goToCardVC(cardDatas: cardDatas, region: self.currentRegion)
                } catch (let err){
                    print("")
                    print("====================================")
                    print("Login URL :: ", url)
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    self.loginButton.isEnabled = true
                }
                break
            case .failure(let err):
                print("")
                print("====================================")
                print("Login URL :: ", url)
                print("failure :: ", err.localizedDescription)
                print("====================================")
                print("")
                self.loginButton.isEnabled = true
                break
            }
        }
    }
    
    func goToCardVC(cardDatas: [CardItemData], region: String) {
        guard let cardVC = self.storyboard?.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else { return }
        cardVC.region = region
        cardVC.uuid = uuid
        cardVC.cardItemData = cardDatas
        
        self.navigationController?.pushViewController(cardVC, animated: true)
        guideLabel.isHidden = true
    }
    
    func jsonToCardList(json: String, isOlympus: Bool) -> CardList {
        let result = CardList(sectors: [])
        let decoder = JSONDecoder()
        
        if isOlympus {
            if let data = json.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
                return decoded
            }
        } else {
            struct CardListNoCustomKeys: Codable {
                var sectors: [CardInfoNoCustomKeys]
            }
            
            if let data = json.data(using: .utf8), let decoded = try? decoder.decode(CardListNoCustomKeys.self, from: data) {
                let sectors = decoded.sectors.map { CardInfo(sector_id: $0.sector_id, sector_name: $0.sector_name, description: $0.description, card_color: $0.card_color, dead_reckoning: $0.dead_reckoning, service_request: $0.service_request, building_level: $0.building_level) }
                return CardList(sectors: sectors)
            }
        }
        
        return result
    }
    
    // DropDown
    private func initDropDown() {
        dropView.layer.cornerRadius = 6
//        dropView.borderColor = .darkgrey4
        dropView.borderColor = .clear
        dropView.layer.shadowOpacity = 0.5
        dropView.layer.shadowOffset = CGSize(width: 1, height: 1)
        dropView.layer.shadowRadius = 1
        
        DropDown.appearance().textColor = UIColor.black // 아이템 텍스트 색상
        DropDown.appearance().selectedTextColor = UIColor.red // 선택된 아이템 텍스트 색상
        DropDown.appearance().backgroundColor = UIColor.white // 아이템 팝업 배경 색상
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGray // 선택한 아이템 배경 색상
        DropDown.appearance().setupCornerRadius(6)
        
        dropText.borderStyle = .none
        if (currentRegion == "") {
            dropText.text = "Region"
        } else {
            dropText.text = self.currentRegion
        }

        dropText.textColor = .darkgrey4
        
        dropDown.dismissMode = .automatic // 팝업을 닫을 모드 설정
    }
    
    private func setDropDown() {
        dropDown.dataSource = self.regions
        
        // anchorView를 통해 UI와 연결
        dropDown.anchorView = self.dropView
            
        // View를 갖리지 않고 View아래에 Item 팝업이 붙도록 설정
        dropDown.bottomOffset = CGPoint(x: 0, y: dropView.bounds.height)
            
        // Item 선택 시 처리
        dropDown.selectionAction = { [weak self] (index, item) in
            //선택한 Item을 TextField에 넣어준다.
            self!.dropText.text = item
            self!.currentRegion = item
            print("Drop Down Clicked : \(self!.currentRegion)")
            setRegion(regionName: self!.currentRegion)
            setServerURL(region: self!.currentRegion)
            self!.setDefaultMessage(region: self!.currentRegion)
            self!.dropImage.image = UIImage.init(named: "showInfoToggle")
        }
            
        // 취소 시 처리
        dropDown.cancelAction = { [weak self] in
            //빈 화면 터치 시 DropDown이 사라지고 아이콘을 원래대로 변경
            self!.dropImage.image = UIImage.init(named: "showInfoToggle")
        }
    }
    
    public func setDefaultMessage(region: String) {
        switch (region) {
        case "Korea":
            self.defaultMeasage = "카드를 터치해 주세요"
        case "Canada":
            self.defaultMeasage = "Touch the card"
        default:
            self.defaultMeasage = "Touch the card"
        }
    }
    
    @IBAction func dropButtonClicked(_ sender: UIButton) {
        dropDown.show()
        self.dropImage.image = UIImage.init(named: "closeInfoToggle")
    }
    
}
