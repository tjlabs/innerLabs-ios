//
//  OverlayCustomView.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/04/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class OverlayCustomView: UIView {
    var showDetail : (() -> ()) = {}
    var hideDetail : (() -> ()) = {}
    
    var isShowDetail: Bool = false

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
