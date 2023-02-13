//
//  WardCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2023/02/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class WardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var wardView: UIView!
    @IBOutlet weak var wardIdLabel: UILabel!
    @IBOutlet weak var wardRssiLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func updateWardInfo() {
        
    }

}
