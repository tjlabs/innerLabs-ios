//
//  TipsTownViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/07/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import Floaty

class TipsTownViewController: UIViewController {

    @IBOutlet var TipsTownView: UIView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    @IBOutlet weak var buildingLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    var serviceManager = ServiceManager()
    var serviceName = "FLD"
    var userId: String = ""
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    
    var buildings = [String]()
    var currentBuilding: String = ""
    var levels = [String: [String]]()
    var levelList = [String]()
    var currentLevel: String = ""
    
    var runMode: String = ""
    var isOpen: Bool = false
    
    // View
    var defaultHeight: CGFloat = 100
    
    // Floating Button
    let floaty = Floaty()
    
    // Chat
    var window: UIWindow?
    
    override func viewWillAppear(_ animated: Bool) {
        
        setCardData(cardData: cardData!)
        
        if (cardData?.sector_id != 0 && cardData?.sector_id != 7) {
            let firstBuilding: String = (cardData?.infoBuilding[0])!
            let firstBuildingLevels: [String] = (cardData?.infoLevel[firstBuilding])!
            
            levelList = firstBuildingLevels
        }
        
        super.viewWillAppear(false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runMode = cardData!.mode
        
        // Service Manger
        serviceManager.startService(id: userId, sector_id: cardData!.sector_id, service: serviceName, mode: cardData!.mode)
//        serviceManager.startService(id: userId, sector_id: 1, service: serviceName, mode: cardData!.mode)
        
        // Floating Button
        setFloatingButton()
        
        self.hideKeyboardWhenTappedAround()
    }
    
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapAuthButton(_ sender: UIButton) {
        serviceManager.getResult(completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = jsonToResult(json: returnedString)
                
                if (result.building_name != "") {
                    self.buildingLabel.text = result.building_name
                    self.levelLabel.text = result.level_name
                }
            }
        })
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        self.cardTopImage.image = UIImage(named: imageName)!
        
        self.buildings = cardData.infoBuilding
        self.levels = cardData.infoLevel
        
        let numBuildings: Int = cardData.infoBuilding.count
        for building in 0..<numBuildings {
            let buildingName: String = cardData.infoBuilding[building]
            let levels: [String] = cardData.infoLevel[buildingName]!
            let numLevels: Int = levels.count
        }
    }
    
    func setFloatingButton() {
        let colorPurple = UIColor(red: 168/255, green: 89/255, blue: 230/255, alpha: 1.0)
        
        floaty.buttonColor = colorPurple
        floaty.plusColor = .white
//        floaty.itemButtonColor = .white
        floaty.openAnimationType = .slideLeft
        
        let itemToBottom = FloatyItem()
        itemToBottom.buttonColor = colorPurple
        itemToBottom.title = "Chat"
        itemToBottom.titleColor = .black
        itemToBottom.icon = UIImage(named: "chat")
        itemToBottom.handler = { [self] itemToBottom in
            goToChatViewController()
            floaty.close()
        }
        floaty.addItem(item: itemToBottom)
        
        self.view.addSubview(floaty)
    }
    
    func jsonToResult(json: String) -> FineLevelDetectionResult {
        let result = FineLevelDetectionResult.init()
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLevelDetectionResult.self, from: data) {
            return decoded
        }

        return result
    }
    
    func goToChatViewController() {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        AppController.shared.show(in: window)
    }
}
