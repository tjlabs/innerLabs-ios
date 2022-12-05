//
//  ZoneCollectionViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/03/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class LevelCollectionViewCell: UICollectionViewCell, UICollectionViewRegisterable {
    
    static var isFromNib = true

    @IBOutlet weak var levelLabel: UILabel! {
        didSet {
            levelLabel.setCharacterSpacing()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setName(level : String, isClicked : Bool){
        levelLabel.text = level
//      self.contentView.backgroundColor = isClicked ? .blue1 : .white
      self.contentView.backgroundColor = isClicked ? .darkgrey4 : .white
      self.levelLabel.font = isClicked ? .boldSystemFont(ofSize: 14) : .systemFont(ofSize: 14)
//      self.levelLabel.textColor = isClicked ? .white : .blue1
        self.levelLabel.textColor = isClicked ? .white : .darkgrey4
    }

}
