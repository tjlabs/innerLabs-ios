//
//  CardCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var sectorImageView: UIImageView!
    
    @IBOutlet weak var sectorName: UILabel!
    @IBOutlet weak var sectorDescription: UILabel!
    
    @IBOutlet weak var sectorImageHeight: NSLayoutConstraint!
    @IBOutlet weak var sectorImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sectorTopSpace: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        sectorImageWidth.constant = 280
        sectorImageHeight.constant = 300
//        sectorImageView.backgroundColor = .black
        
//        print("UIView Width : \(cardView.frame.width)")
//        print("UIView Height : \(cardView.frame.height)")
//        
//        print("CardImageView Width : \(cardImageView.frame.width)")
//        print("CardImageView Height : \(cardImageView.frame.height)")
    }
}
