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

    @IBOutlet weak var cardUIView: UIView!

    @IBOutlet weak var cardHeight: NSLayoutConstraint!
    @IBOutlet weak var cardWidth: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cardShowImage: UIImageView!
    @IBOutlet weak var sectorShowImage: UIImageView!
    
    @IBOutlet weak var sectorShowImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sectorShowImageHeight: NSLayoutConstraint!
    @IBOutlet weak var sectorShowImageLeading: NSLayoutConstraint!
    
    var isAnimate: Bool! = true
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cardUIView.backgroundColor = .clear
    }

    @IBAction func tapDeleteButton(_ sender: UIButton) {
        delete()
    }
    
    func startAnimate() {
        let shakeAnimation = CABasicAnimation(keyPath: "transform.rotation")
        shakeAnimation.duration = 0.05
        shakeAnimation.repeatCount = 4
        shakeAnimation.autoreverses = true
        shakeAnimation.duration = 0.2
        shakeAnimation.repeatCount = 99999
        
        let startAngle: Float = (-2) * 3.14159/180
        let stopAngle = -startAngle
        
        shakeAnimation.fromValue = NSNumber(value: startAngle as Float)
        shakeAnimation.toValue = NSNumber(value: 3 * stopAngle as Float)
        shakeAnimation.autoreverses = true
        shakeAnimation.timeOffset = 290 * drand48()
        
        let layer: CALayer = self.layer
        layer.add(shakeAnimation, forKey:"animate")
        deleteButton.isHidden = false
        isAnimate = true
    }
    
    func stopAnimate() {
        let layer: CALayer = self.layer
        layer.removeAnimation(forKey: "animate")
        self.deleteButton.isHidden = true
        isAnimate = false
    }
}
