//
//  RobotTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/11.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

protocol RobotTableViewCellDelegate: AnyObject {
    func robotTableViewCell(_ cell: RobotTableViewCell, didTapButtonWithValue value: String)
}

class RobotTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    weak var delegate: RobotTableViewCellDelegate?
    
    static let identifier = "RobotTableViewCell"

    @IBOutlet weak var robotIdTextField: UITextField!
    @IBOutlet weak var xTextField: UITextField!
    @IBOutlet weak var yTextField: UITextField!
    
    public var robotId: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        xTextField.delegate = self
        yTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        textField.resignFirstResponder()
        
        return false
    }
    
    @IBAction func tapMonitorButton(_ sender: UIButton) {
        self.robotId = robotIdTextField.text ?? ""
        
        if (self.robotId != "" || self.robotId.contains(" ")) {
            delegate?.robotTableViewCell(self, didTapButtonWithValue: self.robotId)
        }
    }
}
