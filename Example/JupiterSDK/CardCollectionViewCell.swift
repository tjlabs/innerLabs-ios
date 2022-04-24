//
//  CardCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var centerLabel: UILabel!
    
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var sectorImageView: UIImageView!
    
    @IBOutlet weak var sectorName: UILabel!
    @IBOutlet weak var sectorDescription: UILabel!
    
    @IBOutlet weak var cardImageWidth: NSLayoutConstraint!
    @IBOutlet weak var cardImageHeight: NSLayoutConstraint!
    
    @IBOutlet weak var sectorImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sectorImageHeight: NSLayoutConstraint!
    @IBOutlet weak var sectorImageFromTop: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        centerLabel.alpha = 0.0
    }
}
