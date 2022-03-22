//
//  ZoneCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/03/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class ZoneCollectionViewCell: UICollectionViewCell, UICollectionViewRegisterable {
    
    static var isFromNib = true

    @IBOutlet weak var zoneLabel: UILabel! {
        didSet {
            zoneLabel.setCharacterSpacing()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    // MARK: - Custom Method Parts
    
    func setName(floor : String, isClicked : Bool){
        zoneLabel.text = floor
      self.contentView.backgroundColor = isClicked ? .blue1 : .white
      self.zoneLabel.font = isClicked ? .boldSystemFont(ofSize: 14) : .systemFont(ofSize: 14)
      self.zoneLabel.textColor = isClicked ? .white : .blue1
    }

}
