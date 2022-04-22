//
//  ShowCardCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/21.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class ShowCardCollectionViewCell: UICollectionViewCell {
    var delete : (() -> ()) = {}

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cardShowImage: UIImageView!
    @IBOutlet weak var sectorShowImage: UIImageView!
    
    @IBOutlet weak var cardShowImageWidth: NSLayoutConstraint!
    @IBOutlet weak var cardShowImageHeight: NSLayoutConstraint!
    
    @IBOutlet weak var sectorShowImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sectorShowImageHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func tapDeleteButton(_ sender: UIButton) {
        delete()
    }
}
