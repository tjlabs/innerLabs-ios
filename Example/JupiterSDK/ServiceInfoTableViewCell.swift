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
    @IBOutlet weak var detectedLevelLabel: UILabel!
    @IBOutlet weak var velocityLabel: UILabel!
    @IBOutlet weak var indexTxLabel: UILabel!
    @IBOutlet weak var indexRxLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var sccLabel: UILabel!
    @IBOutlet weak var phaseLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func updateResult(data: ResultToDisplay) {
        self.infoOfLevelsLabel.text = data.infoLevels
        self.detectedLevelLabel.text = data.level
        self.velocityLabel.text = String(format: "%.2f", data.velocity)
        self.indexRxLabel.text = String(data.unitIndexRx)
        self.indexTxLabel.text = String(data.unitIndexTx)
        self.lengthLabel.text = String(format: "%.4f", data.unitLength)
        self.headingLabel.text = String(format: "%.2f", data.heading)
        if ( abs(data.scc) < 100 ) {
            self.sccLabel.text = String(format: "%.4f", data.scc)
        } else {
            self.sccLabel.text = "Invalid"
        }
        self.phaseLabel.text = String(data.phase)
    }
}
