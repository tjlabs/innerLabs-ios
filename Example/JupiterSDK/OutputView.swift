//
//  OutputView.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class OutputView: UIView {
    var showDetail : (() -> ()) = {}
    var hideDetail : (() -> ()) = {}
    
    var isShowDetail: Bool = false
    
    @IBOutlet weak var numOfZonesView: UIView!
    @IBOutlet weak var detectedZoneView: UIView!
    @IBOutlet weak var infoView: UIView!
    
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var infoViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var numOfZonesLabel: UILabel!
    @IBOutlet weak var detectedZoneLabel: UILabel!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        infoViewHeight.constant = 120
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        infoViewHeight.constant = 120
        numOfZonesView.clipsToBounds = true
        numOfZonesView.layer.cornerRadius = 20
        
        detectedZoneView.clipsToBounds = true
        detectedZoneView.layer.cornerRadius = 20
        
        infoView.clipsToBounds = true
        infoView.layer.cornerRadius = 20
        
    }
    
    @IBAction func tapDetailButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            showDetail()
            isShowDetail = true
        }
        else {
            hideDetail()
            isShowDetail = false
        }
    }
    
}
