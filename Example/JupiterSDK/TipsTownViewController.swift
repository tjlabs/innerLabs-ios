//
//  TipsTownViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/07/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK

class TipsTownViewController: UIViewController {

    @IBOutlet var TipsTownView: UIView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
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
        
        self.hideKeyboardWhenTappedAround()
    }
    
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
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
}
