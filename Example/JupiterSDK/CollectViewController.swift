//
//  CollectViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/06/20.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

protocol CollectViewPageDelegate {
    func sendPage(data: Int)
}

class CollectViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
//        setCardData(cardData: cardData!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var delegate : CollectViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    var uuid: String = ""
    
    func setCardData(cardData: CardItemData) {
//        self.sectorNameLabel.text = cardData.sector_name
        
//        let imageName: String = cardData.cardColor + "CardTop"
//        self.cardTopImage.image = UIImage(named: imageName)!
    }
}
