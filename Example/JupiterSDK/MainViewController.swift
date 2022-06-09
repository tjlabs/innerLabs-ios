//
//  ViewController.swift
//  JupiterSDK
//
//  Created by Leo on 03/22/2022.
//  Copyright (c) 2022 Leo. All rights reserved.
//

import UIKit
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
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            
            let login = Login(user_id: uuid)
            postLogin(url: JUPITER_URL, input: login)
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
//        print("Save UUID : \(isSaveUuid)")
    }
    
    func postLogin(url: String, input: Login) {
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        // [http 요청 수행 실시]
        print("")
        print("====================================")
        print("주 소 :: ", url)
        print("-------------------------------")
        print("데이터 :: ", input)
        print("====================================")
        print("")
        
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
                    
                    print("Sector List :", myCard)
                    
                    var cardDatas = [CardItemData]()
                    
                    if (myCard.isEmpty) {
                        print("최초 사용자 입니다")
                        cardDatas.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: "카드를 터치해주세요", cardColor: "purple", mode: 0, infoLevel: ["7F"], infoBuilding: ["S3"]))
                    } else {
                        print("최초 사용자가 아닙니다")
                        cardDatas.append(CardItemData(sector_id: 0, sector_name: "JUPITER", description: "카드를 터치해주세요", cardColor: "purple", mode: 0, infoLevel: ["7F"], infoBuilding: ["S3"]))
                        
                        print("Sector List :", myCard)
                        
                        KingfisherManager.shared.cache.clearMemoryCache()
                        KingfisherManager.shared.cache.clearDiskCache { print("Clear Cache Done !") }
                        
                        for card in 0..<myCard.count {
                            let cardInfo: CardInfo = myCard[card]
                            let id: Int = cardInfo.sector_id
                            let name: String = cardInfo.sector_name
                            let description: String = cardInfo.description
                            let cardColor: String = cardInfo.cardColor
                            
                            let mode: Int = cardInfo.mode
                            let infoLevel: [String] = cardInfo.infoLevel.components(separatedBy: " ")
                            let infoBuilding: [String] = cardInfo.infoBuilding.components(separatedBy: " ")
                            
                            // KingFisher Image Download
                            let urlSector = URL(string: "https://storage.googleapis.com/jupiter_image/card/\(id)/main_image.png")
                            let urlSectorShow = URL(string: "https://storage.googleapis.com/jupiter_image/card/\(id)/edit_image.png")
                            
                            let resourceSector = ImageResource(downloadURL: urlSector!, cacheKey: "\(id)Main")
                            let resourceSectorShow = ImageResource(downloadURL: urlSectorShow!, cacheKey: "\(id)Show")
                            
                            KingfisherManager.shared.retrieveImage(with: resourceSector, completionHandler: nil)
                            KingfisherManager.shared.retrieveImage(with: resourceSectorShow, completionHandler: nil)
                            
                            cardDatas.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, infoLevel: infoLevel, infoBuilding: infoBuilding))
                        }
                    }
                    
                    goToCardVC(cardDatas: cardDatas)
                    
//                    DispatchQueue.main.async {
//
//                    }
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
                print("")
                print("====================================")
                print("응답 코드 :: ", response.response?.statusCode ?? 0)
                print("-------------------------------")
                print("에 러 :: ", err.localizedDescription)
                print("====================================")
                print("")
                
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
    
}
