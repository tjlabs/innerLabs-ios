//
//  ServiceInfoTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/11.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK

class ServiceInfoTableViewCell: UITableViewCell {
    
    static let identifier = "ServiceInfoTableViewCell"
    
    @IBOutlet weak var infoOfLevelsLabel: UILabel!
    @IBOutlet weak var numberOfLevelsLabel: UILabel!
    @IBOutlet weak var detectedLevelLabel: UILabel!
    @IBOutlet weak var IndexTxLabel: UILabel!
    @IBOutlet weak var IndexRxLabel: UILabel!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var sccLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func updateResult(data: ResultToDisplay) {
        self.detectedLevelLabel.text = data.level
        self.IndexRxLabel.text = String(data.unitIndexRx)
        self.IndexTxLabel.text = String(data.unitIndexTx)
        self.lengthLabel.text = String(format: "%.4f", data.unitLength)
        self.sccLabel.text = String(format: "%.4f", data.scc)
        self.statusLabel.text = String(data.status)
    }
}
