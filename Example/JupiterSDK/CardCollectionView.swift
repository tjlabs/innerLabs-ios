//
//  CardCollectionView.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

struct CardItemData: Codable {
    var name: String
    var description: String
    var cardImage: String
    var sectorImage: String
    var code: String
    var sectorID: Int
    var numZones: String
    var order: Int
}

struct CardList: Codable {
    var cards = [CardItemData]()
}

protocol CardCollectionViewDelegate {
    func cardCollectionView(_ cardCollectionView: CardCollectionView, scrollViewDidEndDecelerating scrollView: UIScrollView)
    
    func cardCollectionView(_ cardCollectionView: CardCollectionView, scrollViewDidScroll scrollView: UIScrollView)
    
    func cardCollectionView(_ cardCollectionView: CardCollectionView, flipped state: Bool)
}

class CardCollectionView: UIView {
    
    var collectionView: UICollectionView!
    
    var itemDatas = [CardItemData]()
    
    var delegate: CardCollectionViewDelegate?
    
    var currentIndex: Int = 0
    
    var isDragging = false

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
