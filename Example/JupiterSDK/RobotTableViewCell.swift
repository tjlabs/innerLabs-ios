//
//  RobotTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/11.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class RobotTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    static let identifier = "RobotTableViewCell"

    @IBOutlet weak var xTextField: UITextField!
    @IBOutlet weak var yTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        xTextField.delegate = self
        yTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        textField.resignFirstResponder()
        
        return false
    }
}
