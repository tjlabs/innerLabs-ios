//
//  ViewController.swift
//  JupiterSDK
//
//  Created by Leo on 03/22/2022.
//  Copyright (c) 2022 Leo. All rights reserved.
//

import UIKit
import JupiterSDK

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var guideLabel: UILabel!
    
    @IBOutlet weak var saveUuidButton: UIButton!
    
    
    var isSaveUuid: Bool = false
    var uuid: String = ""
    
    let defaults = UserDefaults.standard
    
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
            
            guard let cardVC = self.storyboard?.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else { return }
            cardVC.uuid = uuid
            
            // Card 정보 가져오기
            var cardDatas = [CardItemData]()
            cardDatas.append(CardItemData(name: "JUPITER\nService guide", description: "카드를 터치해주세요", cardImage: "purpleCard", cardShowImage: "purpleCardShow",
                                          sectorImage: "sectorDefault", sectorShowImage: "tjlabsShow", cardTopImage: "cardTopPurple", code: "purple", sectorID: 0, numZones: 3, order: 0))
            cardDatas.append(CardItemData(name: "KIST", description: "한국과학기술연구원 L8", cardImage: "orangeCard", cardShowImage: "orangeCardShow",
                                          sectorImage: "sectorKist", sectorShowImage: "kistShow", cardTopImage: "cardTopOrange", code: "orange", sectorID: 1, numZones: 3, order: 1))
            cardDatas.append(CardItemData(name: "오토웨이타워(V)", description: "For Vehicle", cardImage: "grayCard", cardShowImage: "grayCardShow",
                                          sectorImage: "sectorParkingCar", sectorShowImage: "parkingCarShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 2, numZones: 3, order: 2))
            cardDatas.append(CardItemData(name: "오토웨이타워(P)", description: "For Pedestrian", cardImage: "grayCard", cardShowImage: "grayCardShow",
                                          sectorImage: "sectorParkingPed", sectorShowImage: "parkingPedShow", cardTopImage: "cardTopGray", code: "gray", sectorID: 3, numZones: 3, order: 3))
            cardDatas.append(CardItemData(name: "COEX", description: "지하주차장", cardImage: "pinkCard", cardShowImage: "pinkCardShow",
                                          sectorImage: "sectorCoex", sectorShowImage: "coexShow", cardTopImage: "cardTopPink", code: "pink", sectorID: 4, numZones: 3, order: 4))
            
            cardVC.cardItemData = cardDatas
            
            self.navigationController?.pushViewController(cardVC, animated: true)
            guideLabel.isHidden = true
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
    
}
