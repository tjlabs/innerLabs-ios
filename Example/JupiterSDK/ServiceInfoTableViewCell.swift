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
        
    }
    
    func updateResult(data: ResultToDisplay) {
        self.infoOfLevelsLabel.text = data.infoLevels
        self.numberOfLevelsLabel.text = String(data.numLevels)
        self.detectedLevelLabel.text = data.level
        self.IndexRxLabel.text = String(data.unitIndexRx)
        self.IndexTxLabel.text = String(data.unitIndexTx)
        self.lengthLabel.text = String(format: "%.4f", data.unitLength)
        if ( abs(data.scc) < 100 ) {
            self.sccLabel.text = String(format: "%.4f", data.scc)
        } else {
            self.sccLabel.text = "Unvalid"
        }
        self.statusLabel.text = String(data.status)
    }
}
