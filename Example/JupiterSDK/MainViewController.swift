//
//  ViewController.swift
//  JupiterSDK
//
//  Created by Leo on 03/22/2022.
//  Copyright (c) 2022 Leo. All rights reserved.
//

import UIKit
import Alamofire
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
            
            let url = "https://where-card-skrgq3jc5a-du.a.run.app/sectors"
            let login = Login(user_id: uuid)
            postLogin(url: url, input: login)
            
            
//            if (cards.isEmpty) {
//                // 최초 사용자
//                print("최초 로그인 입니다")
//
//                // Card 정보 가져오기
//                cardDatas.append(CardItemData(name: "JUPITER\nService guide", description: "카드를 터치해주세요", cardImage: "purpleCard", cardShowImage: "purpleCardShow",
//                                              sectorImage: "sectorDefault", sectorShowImage: "tjlabsShow", cardTopImage: "cardTopPurple", code: "purple", sectorID: 0, infoLevel: ["1F","2F","3F","4F"]))
//                cardDatas.append(CardItemData(name: "KIST", description: "한국과학기술연구원 L8", cardImage: "orangeCard", cardShowImage: "orangeCardShow",
//                                              sectorImage: "sectorKist", sectorShowImage: "kistShow", cardTopImage: "cardTopOrange", code: "orange", sectorID: 1, infoLevel: ["B1F"]))
//                cardDatas.append(CardItemData(name: "오토웨이타워(V)", description: "For Vehicle", cardImage: "grayCard", cardShowImage: "grayCardShow",
//                                              sectorImage: "sectorParkingCar", sectorShowImage: "parkingCarShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, infoLevel: ["B4F","B3F"]))
//                cardDatas.append(CardItemData(name: "오토웨이타워(P)", description: "For Pedestrian", cardImage: "grayCard", cardShowImage: "grayCardShow",
//                                              sectorImage: "sectorParkingPed", sectorShowImage: "parkingPedShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, infoLevel: ["B4F","B3F"]))
//                cardDatas.append(CardItemData(name: "COEX", description: "지하주차장", cardImage: "pinkCard", cardShowImage: "pinkCardShow",
//                                              sectorImage: "sectorCoex", sectorShowImage: "coexShow", cardTopImage: "cardTopPink", code: "pink", sectorID: 3, infoLevel: ["B2F","B1F","1F","2F"]))
//
////                let addCard = AddCard(user_id: uuid, sector_code: "KIST!1966")
////                let result = networkManager.putAddCard(url: url, input: addCard)
////                print(result)
//            } else {
//                print("최초 사용자가 아닙니다")
//                print(cards)
//            }
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
                    
                    let result = String(data: res, encoding: .utf8) ?? ""
                    
                    let returnedString = String(decoding: response.data!, as: UTF8.self)
                    let list = jsonToCardList(json: returnedString)
                    
                    print("CARD!!")
                    print(list)
                    
                    var cardDatas = [CardItemData]()
                    
                    if (result.isEmpty) {
                        print("최초 사용자 입니다")
                        cardDatas.append(CardItemData(name: "JUPITER\nService guide", description: "카드를 터치해주세요", cardImage: "purpleCard", cardShowImage: "purpleCardShow",
                                                      sectorImage: "sectorDefault", sectorShowImage: "tjlabsShow", cardTopImage: "cardTopPurple", code: "purple", sectorID: 0, infoLevel: ["1F","2F","3F","4F"]))
                        cardDatas.append(CardItemData(name: "KIST", description: "한국과학기술연구원 L8", cardImage: "orangeCard", cardShowImage: "orangeCardShow",
                                                      sectorImage: "sectorKist", sectorShowImage: "kistShow", cardTopImage: "cardTopOrange", code: "orange", sectorID: 1, infoLevel: ["B1F"]))
                        cardDatas.append(CardItemData(name: "오토웨이타워(V)", description: "For Vehicle", cardImage: "grayCard", cardShowImage: "grayCardShow",
                                                      sectorImage: "sectorParkingCar", sectorShowImage: "parkingCarShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, infoLevel: ["B4F","B3F"]))
                        cardDatas.append(CardItemData(name: "오토웨이타워(P)", description: "For Pedestrian", cardImage: "grayCard", cardShowImage: "grayCardShow",
                                                      sectorImage: "sectorParkingPed", sectorShowImage: "parkingPedShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, infoLevel: ["B4F","B3F"]))
                        cardDatas.append(CardItemData(name: "COEX", description: "지하주차장", cardImage: "pinkCard", cardShowImage: "pinkCardShow",
                                                      sectorImage: "sectorCoex", sectorShowImage: "coexShow", cardTopImage: "cardTopPink", code: "pink", sectorID: 3, infoLevel: ["B2F","B1F","1F","2F"]))
                        
                    } else {
                        print("최초 사용자가 아닙니다")
                        cardDatas.append(CardItemData(name: "JUPITER\nService guide", description: "카드를 터치해주세요", cardImage: "purpleCard", cardShowImage: "purpleCardShow",
                                                      sectorImage: "sectorDefault", sectorShowImage: "tjlabsShow", cardTopImage: "cardTopPurple", code: "purple", sectorID: 0, infoLevel: ["1F","2F","3F","4F"]))
                        cardDatas.append(CardItemData(name: "KIST", description: "한국과학기술연구원 L8", cardImage: "orangeCard", cardShowImage: "orangeCardShow",
                                                      sectorImage: "sectorKist", sectorShowImage: "kistShow", cardTopImage: "cardTopOrange", code: "orange", sectorID: 1, infoLevel: ["B1F"]))
                        cardDatas.append(CardItemData(name: "오토웨이타워(V)", description: "For Vehicle", cardImage: "grayCard", cardShowImage: "grayCardShow",
                                                      sectorImage: "sectorParkingCar", sectorShowImage: "parkingCarShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, infoLevel: ["B4F","B3F"]))
                        cardDatas.append(CardItemData(name: "오토웨이타워(P)", description: "For Pedestrian", cardImage: "grayCard", cardShowImage: "grayCardShow",
                                                      sectorImage: "sectorParkingPed", sectorShowImage: "parkingPedShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, infoLevel: ["B4F","B3F"]))
                        cardDatas.append(CardItemData(name: "COEX", description: "지하주차장", cardImage: "pinkCard", cardShowImage: "pinkCardShow",
                                                      sectorImage: "sectorCoex", sectorShowImage: "coexShow", cardTopImage: "cardTopPink", code: "pink", sectorID: 3, infoLevel: ["B2F","B1F","1F","2F"]))
                    }
                    
                    goToCardVC(cardDatas: cardDatas)
                    
                    DispatchQueue.main.async {
                        
                    }
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
        let result = CardList(cards: [])
//        let result = CardInfo()
        let decoder = JSONDecoder()
        
        let jsonString = json
        print("JSON :", jsonString)
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
            
            return decoded
        }
        
        return result
    }
    
}
