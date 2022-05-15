//
//  UILabelExtension.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {

  func setCharacterSpacing(kernValue: CGFloat = -0.3) {

        guard let labelText = text else { return }

        let attributedString: NSMutableAttributedString
        if let labelAttributedText = attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

        // Character spacing attribute
    attributedString.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSMakeRange(0, attributedString.length))

        attributedText = attributedString
    }

}
