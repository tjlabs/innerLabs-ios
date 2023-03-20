//
//  JupiterGuideTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class JupiterGuideTableViewCell: UITableViewCell {
    
    static let identifier = "JupiterGuideTableViewCell"
    
    @IBOutlet weak var guideTextView: UITextView!
    var guideText: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setGuideText()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setGuideText() {
        let locale = Locale.current
        if let countryCode = locale.regionCode, countryCode == "KR" {
            self.guideText = "우리는 지금까지 GPS를 활용한 세상에 살았습니다.\n TJLABS 는 실내 위치 측위 기술을 통한 새로운 세상\n‘이너버스’를 열고자 합니다.\n알지 못했던 것을 알게 되는 것, 보이지 않던 것이 보이는 것은 생각보다 더 대단할 일이 될 것입니다.\n이제는 지도에 외형만 있던 건물 내부 구조를 볼 수 있습니다. 낯선 대형 건물의 내부와 지하에서 더 이상 헤매지 않고, 내 손안에 키오스크가 들어옵니다.\n최근 이슈가 되는 산업단지, 공장, 건설 현장에서의 안타까운 사고 대부분은 작업자의 위치를 알 수 없거나, 작업자가 위험지역을 인지하지 못했기 때문입니다.\nTJLABS 는 실내/외 작업자와 위험시설 및 위험지역 간 접근을 막고, 비상시 빠르게 해당 위치를 확인할 수 있습니다.\n라이다 없이도 위치를 잃지 않는 로봇과 함께 살아가는 세상.\n가상화폐 다음은 가상 부동산이 될 것이고, 위치가 중심이 될 것입니다.\n“Location opens innerverse.”"
        } else {
            self.guideText = "Until now, we have lived in a world that utilizes GPS.\n TJLABS wants to open a new world\n'Innerverse' through indoor positioning technology.\nKnowing the unknown, seeing the invisible is thinking. It will be even greater than that.\nNow you can see the inside structure of the building, which was just an outline on the map. No more wandering inside or underground of a large unfamiliar building, a kiosk is in my hand.\nIn most of the unfortunate accidents in industrial complexes, factories, and construction sites that have become a recent issue, the location of the worker is unknown or the worker is in danger. This is because it was not aware of the area.\nTJLABS blocks access between indoor/outdoor workers, hazardous facilities and hazardous areas, and can quickly check the location in case of an emergency.\nA world where robots do not lose their position without LiDAR. \nNext to virtual currency will be virtual real estate, and location will be central.\n“Location opens innerverse.”"
        }
        self.guideTextView.text = self.guideText
    }
}
