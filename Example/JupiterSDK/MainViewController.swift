import UIKit
import Alamofire
import Kingfisher
import DropDown
import JupiterSDK

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var saveUserIDButton: UIButton!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    var isSaveUserID: Bool = false
    
    var userID: String = ""
    var deviceModel: String = ""
    var OS: String = ""
    var OSVersion: Int = 0
    var SDKVersion: String = ""
    
    let userDefaults = UserDefaults.standard

    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var dropImage: UIImageView!
    @IBOutlet weak var dropText: UITextField!
    @IBOutlet weak var dropButton: UIButton!
    
    var regions: [String] = ["Korea", "Canada", "US(East)"]
    var currentRegion: String = "Korea"
    var defaultMeasage: String = ""
    let dropDown = DropDown()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        codeTextField.delegate = self
        
        initDropDown()
        setDropDown()
        loadUserID()
        initUserInfo()
        
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
    }
    
    private func loadUserID() {
        if let userID = userDefaults.string(forKey: "userID") {
            codeTextField.text = userID
            saveUserIDButton.isSelected.toggle()
            isSaveUserID = true
        }
    }
    
    private func initUserInfo() {
        deviceModel = UIDevice.modelName
        OS = UIDevice.current.systemVersion
        let arr = OS.components(separatedBy: ".")
        OSVersion = Int(arr[0]) ?? 0
        SDKVersion = ServiceManager.sdkVersion
        sdkVersionLabel.text = SDKVersion
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func tapLoginButton(_ sender: UIButton) {
        if let userID = codeTextField.text { self.userID = userID }
        if (userID == "" || userID.contains(" ")) {
            guideLabel.isHidden = false
        } else {
            saveUserID()
            let userInfo = UserInfo(user_id: userID, device_model: deviceModel, os_version: OSVersion, sdk_version: SDKVersion)
            let loginURL = IS_OLYMPUS ? USER_LOGIN_URL : LOGIN_URL
            self.loginButton.isEnabled = false
            Network.shared.postLogin(url: loginURL, input: userInfo, completion: { [self] statusCode, returnedString in
                if statusCode == 200 {
                    let userCardList = makeUserCardList(returnedString: returnedString)
                    self.loginButton.isEnabled = true
                    goToCardVC(cardDatas: userCardList, region: self.currentRegion)
                } else {
                    self.loginButton.isEnabled = true
                }
            })
        }
    }
    
    private func saveUserID() {
        if (isSaveUserID) {
            userDefaults.set(self.userID, forKey: "userID")
        } else {
            userDefaults.set(nil, forKey: "userID")
        }
        userDefaults.synchronize()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeTextField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func tapSaveUserIDButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            isSaveUserID = true
        } else {
            isSaveUserID = false
        }
    }
    
    private func makeUserCardList(returnedString: String) -> [CardItemData] {
        let list = jsonToCardList(json: returnedString, isOlympus: IS_OLYMPUS)
        let myCard = list.sectors
        var reorderedCard = [CardInfo]()
        var cardList = [CardItemData]()
        if (myCard.isEmpty) {
            print("최초 사용자 입니다")
            cardList.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: self.defaultMeasage, cardColor: "purple", mode: "pdr", service: "NONE", infoBuilding: ["S3"], infoLevel: ["S3":["7F"]]))
        } else {
            print("최초 사용자가 아닙니다")
            cardList.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: self.defaultMeasage, cardColor: "purple", mode: "pdr", service: "NONE", infoBuilding: ["S3"], infoLevel: ["S3":["7F"]]))
            
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
                var infoLevel = [String: [String]]()
                for building in 0..<buildings_n_levels.count {
                    let buildingName: String = buildings_n_levels[building][0]
                    let levelName: String = buildings_n_levels[building][1]
                    
                    // Building
                    if !(infoBuilding.contains(buildingName)) {
                        infoBuilding.append(buildingName)
                    }
                    
                    // Level
                    if let value = infoLevel[buildingName] {
                        var levels: [String] = value
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
                cardList.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, service: service, infoBuilding: infoBuilding, infoLevel: infoLevel))
            }
        }
        return cardList
    }
    
    private func goToCardVC(cardDatas: [CardItemData], region: String) {
        guard let cardVC = self.storyboard?.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else { return }
        cardVC.region = region
        cardVC.uuid = userID
        cardVC.cardItemData = cardDatas
        
        self.navigationController?.pushViewController(cardVC, animated: true)
        guideLabel.isHidden = true
    }
    
    // DropDown
    private func initDropDown() {
        dropView.layer.cornerRadius = 6
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
    
    private func setDefaultMessage(region: String) {
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
