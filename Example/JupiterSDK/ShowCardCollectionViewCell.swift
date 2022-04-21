//
//  ShowCardCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class ShowCardCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var showCardImage: UIImageView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        deleteButton.alpha = 0.0
        // Initialization code
    }

}
