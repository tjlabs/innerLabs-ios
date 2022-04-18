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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        print("CardCollectionViewCell Registered")
    }
}
