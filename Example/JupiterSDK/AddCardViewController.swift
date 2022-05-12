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
}

class AddCardViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var responseLabel: UILabel!
    
    var uuid: String = ""
    var code: String = ""
    var cardItemData: [CardItemData] = []

    var delegate : AddCardDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeTextField.delegate = self
        
        guard let presentingVC = self.presentingViewController else { return }
        print("Storyboard : \(presentingVC)")
    }

    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendCardItemData(data: cardItemData)
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func tapConfirmButton(_ sender: UIButton) {
        codeTextField.resignFirstResponder()
        
        self.code = codeTextField.text ?? ""

        
        // Add Card
        let url = JUPITER_URL
        
        let input = AddCard(user_id: uuid, sector_code: code)
        
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
            method: .put, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
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
                    let addedCard = self.jsonToCard(json: returnedString)
                    print(addedCard.message)
                    
                    if (addedCard.message == "Update Success") {
                        self.responseLabel.text = "\(addedCard.sector_name) 카드가 정상적으로 추가됐습니다"
                        self.responseLabel.alpha = 1.0
                        
                        
                        let id: Int = addedCard.sector_id
                        let name: String = addedCard.sector_name
                        let description: String = addedCard.description
                        let cardColor: String = addedCard.cardColor
                        let mode: Int = addedCard.mode
                        let infoLevel: [String] = addedCard.infoLevel.components(separatedBy: " ")
                        
                        self.cardItemData.append(CardItemData(sector_id: id, sector_name: name, description: description, cardColor: cardColor, mode: mode, infoLevel: infoLevel))
                    } else {
                        self.responseLabel.text = "유효한 코드를 입력해주세요 !!"
                        self.responseLabel.alpha = 1.0
                    }
                    
                    
                    // [비동기 작업 수행]
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
                
                self.responseLabel.text = "유효한 코드를 입력해주세요 !!"
                self.responseLabel.alpha = 1.0
                
                break
            }
        }
    }
    
    func jsonToCard(json: String) -> AddCardResponse {
        let result = AddCardResponse(message: "", sector_id: 100, sector_name: "", description: "", cardColor: "", mode: 0, infoLevel: "")
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(AddCardResponse.self, from: data) {
            
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
    
    func putAddCard(url: String, input: AddCard) -> String {
        var result: String = ""
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
            method: .put, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
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
                    
                    result = String(data: res, encoding: .utf8) ?? ""
                    // [비동기 작업 수행]
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
        return result
    }
}
