//
//  MapContainerTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/03/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import Charts
import Kingfisher
import DropDown

class SectorContainerTableViewCell: UITableViewCell {
    
    static let identifier = "SectorContainerTableViewCell"
    
    @IBOutlet weak var levelCollectionView: UICollectionView!

    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    @IBOutlet weak var switchButton: CustomSwitchButton!
    @IBOutlet weak var noImageLabel: UILabel!
    
    // DropDown
    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var dropImage: UIImageView!
    @IBOutlet weak var dropText: UITextField!
    @IBOutlet weak var dropButton: UIButton!
    
    let dropDown = DropDown()
    
    var cardData: CardItemData?
    var RP: [String: [[Double]]]?
    var chartLimits: [String: [Double]]?
    var XY: [Double] = [0, 0]
    var flagRP: Bool = false

    private var buildings = [String]()
    private var levels = [String: [String]]()
    
    private var matchedLevels = [String]()
    
    private var currentBuilding: String = ""
    private var currentLevel: String = ""
    
    private var countLevelChanged: Int = 0
    
    var sectorID: Int = 0
    var building: String = ""
    
    var modeAuto: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        switchButton.delegate = self
        let switchColor: (UIColor, UIColor) = (#colorLiteral(red: 0.5291011186, green: 0.7673488115, blue: 1, alpha: 1), #colorLiteral(red: 0.2705247761, green: 0.3820963617, blue: 1, alpha: 1))
        switchButton.onColor = switchColor
        
        setCells()
        setLevelCollectionView()
        
        initDropDown()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    private func initDropDown() {
        dropView.layer.cornerRadius = 6
        dropView.borderColor = .blue1
        
        DropDown.appearance().textColor = UIColor.black // 아이템 텍스트 색상
        DropDown.appearance().selectedTextColor = UIColor.red // 선택된 아이템 텍스트 색상
        DropDown.appearance().backgroundColor = UIColor.white // 아이템 팝업 배경 색상
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGray // 선택한 아이템 배경 색상
        DropDown.appearance().setupCornerRadius(6)
        
        dropText.borderStyle = .none
        dropText.text = "Buildings"
        dropText.textColor = .blue1
        
        dropDown.dismissMode = .automatic // 팝업을 닫을 모드 설정
    }
    
    private func setDropDown() {
        dropDown.dataSource = self.buildings
        
        // anchorView를 통해 UI와 연결
        dropDown.anchorView = self.dropView
            
        // View를 갖리지 않고 View아래에 Item 팝업이 붙도록 설정
        dropDown.bottomOffset = CGPoint(x: 0, y: dropView.bounds.height)
            
        // Item 선택 시 처리
        dropDown.selectionAction = { [weak self] (index, item) in
            //선택한 Item을 TextField에 넣어준다.
            self!.dropText.text = item
            self!.currentBuilding = item
            self!.levelCollectionView.reloadData()
            self!.dropImage.image = UIImage.init(named: "showInfoToggle")
        }
            
        // 취소 시 처리
        dropDown.cancelAction = { [weak self] in
            //빈 화면 터치 시 DropDown이 사라지고 아이콘을 원래대로 변경
            self!.dropImage.image = UIImage.init(named: "showInfoToggle")
        }
    }
    
    @IBAction func dropDownClicked(_ sender: Any) {
        dropDown.show() // 아이템 팝업을 보여준다.
        // 아이콘 이미지를 변경하여 DropDown이 펼쳐진 것을 표현
        self.dropImage.image = UIImage.init(named: "closeInfoToggle")
    }
    
    
    private func setCells() {
        LevelCollectionViewCell.register(target: levelCollectionView)
    }
    
    private func setLevelCollectionView() {
        levelCollectionView.delegate = self
        levelCollectionView.dataSource = self
        levelCollectionView.reloadData()
    }
    
    private func fetchLevel(building: String, level: String, flag: Bool) {
//        let imageName: String = "\(currentBuilding)_\(currentLevel)"
//
//        if let imageToDraw = UIImage(named: imageName) {
//            noImageLabel.isHidden = true
//            imageLevel.isHidden = false
//            imageLevel.image = imageToDraw
//        } else {
//            imageLevel.isHidden = true
//            noImageLabel.isHidden = false
//        }
//        imageLevel.image = UIImage(named: imageName)
//        print("Width :", imageLevel.image!.size.width)
//        print("Height :", imageLevel.image!.size.height)
        
        // Building -> Level Image Download From URL
        if (!flag) {
            if let urlLevel = URL(string: "https://storage.googleapis.com/jupiter_image/map/\(sectorID)/\(building)_\(level).png") {
                let data = try? Data(contentsOf: urlLevel)
                if (data != nil) {
                    let resourceBuildingLevel = ImageResource(downloadURL: urlLevel, cacheKey: "\(sectorID)_\(building)_\(level)_image")
                    
                    scatterChart.isHidden = false
                    imageLevel.isHidden = false
                    noImageLabel.isHidden = true
                    imageLevel.kf.setImage(with: resourceBuildingLevel, placeholder: nil, options: [.transition(.fade(0.8))], completionHandler: nil)
                } else {
                    scatterChart.isHidden = true
                    imageLevel.isHidden = true
                    noImageLabel.isHidden = false
                }
            } else {
                scatterChart.isHidden = true
                imageLevel.isHidden = true
                noImageLabel.isHidden = false
            }
        } else {
            scatterChart.isHidden = false
            imageLevel.isHidden = false
            noImageLabel.isHidden = true
            
            imageLevel.image = UIImage(named: "emptyLevel")
        }
    }
    
    private func drawRP(RP_X: [Double], RP_Y: [Double], XY: [Double], limits: [Double]) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y

        let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
        }
        
        let values2 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "RP")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.square)
        set1.setColor(UIColor.yellow)
        set1.scatterShapeSize = 8
        
        let set2 = ScatterChartDataSet(entries: values2, label: "User")
        set2.drawValuesEnabled = false
        set2.setScatterShape(.circle)
        set2.setColor(UIColor.systemRed)
        set2.scatterShapeSize = 12
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        let chartFlag: Bool = false
        
        // Configure Chart
//        scatterChart.xAxis.axisMinimum = xMin + limits[0]
//        scatterChart.xAxis.axisMaximum = xMax + limits[1]
//        scatterChart.leftAxis.axisMinimum = yMin + limits[2]
//        scatterChart.leftAxis.axisMaximum = yMax + limits[3]
        
        scatterChart.xAxis.axisMinimum = xMin-2
        scatterChart.xAxis.axisMaximum = xMax+2
        scatterChart.leftAxis.axisMinimum = yMin-6
        scatterChart.leftAxis.axisMaximum = yMax+6
        
//        if (currentLevel == "B1") {
//            scatterChart.xAxis.axisMinimum = xMin-6
//            scatterChart.xAxis.axisMaximum = xMax+9.5
//            scatterChart.leftAxis.axisMinimum = yMin-40
//            scatterChart.leftAxis.axisMaximum = yMax+38.5
//        }
//        else if (currentLevel == "B2") {
//            scatterChart.xAxis.axisMinimum = xMin-28
//            scatterChart.xAxis.axisMaximum = xMax+12
//            scatterChart.leftAxis.axisMinimum = yMin-2
//            scatterChart.leftAxis.axisMaximum = yMax+39.5
//        }
//        else if (currentLevel == "B3") {
//            scatterChart.xAxis.axisMinimum = xMin-3.8
//            scatterChart.xAxis.axisMaximum = xMax+6
//            scatterChart.leftAxis.axisMinimum = yMin-11.3
//            scatterChart.leftAxis.axisMaximum = yMax+1.5
//        } else if (currentLevel == "B4") {
//            scatterChart.xAxis.axisMinimum = xMin-9
//            scatterChart.xAxis.axisMaximum = xMax
//            scatterChart.leftAxis.axisMinimum = yMin-15
//            scatterChart.leftAxis.axisMaximum = yMax+25.5
//        } else {
//            scatterChart.xAxis.axisMinimum = xMin-10
//            scatterChart.xAxis.axisMaximum = xMax+10
//            scatterChart.leftAxis.axisMinimum = yMin-10
//            scatterChart.leftAxis.axisMaximum = yMax+10
//        }
        
        scatterChart.xAxis.drawGridLinesEnabled = chartFlag
        scatterChart.leftAxis.drawGridLinesEnabled = chartFlag
        scatterChart.rightAxis.drawGridLinesEnabled = chartFlag
        
        scatterChart.xAxis.drawAxisLineEnabled = chartFlag
        scatterChart.leftAxis.drawAxisLineEnabled = chartFlag
        scatterChart.rightAxis.drawAxisLineEnabled = chartFlag
        
        scatterChart.xAxis.centerAxisLabelsEnabled = chartFlag
        scatterChart.leftAxis.centerAxisLabelsEnabled = chartFlag
        scatterChart.rightAxis.centerAxisLabelsEnabled = chartFlag

        scatterChart.xAxis.drawLabelsEnabled = chartFlag
        scatterChart.leftAxis.drawLabelsEnabled = chartFlag
        scatterChart.rightAxis.drawLabelsEnabled = chartFlag
        
        scatterChart.legend.enabled = chartFlag
        
        scatterChart.backgroundColor = .clear
        
        scatterChart.data = chartData
    }
    
    private func drawUser(RP_X: [Double], RP_Y: [Double], XY: [Double], limits: [Double]) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y
        
        let values1 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "USER")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.circle)

        set1.setColor(UIColor.systemRed)
        set1.scatterShapeSize = 16
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.setDrawValues(false)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        let chartFlag: Bool = false
        
        // Configure Chart
        print("Limits :", limits)
        scatterChart.xAxis.axisMinimum = xMin + limits[0]
        scatterChart.xAxis.axisMaximum = xMax + limits[1]
        scatterChart.leftAxis.axisMinimum = yMin + limits[2]
        scatterChart.leftAxis.axisMaximum = yMax + limits[3]
        
        
        scatterChart.xAxis.drawGridLinesEnabled = chartFlag
        scatterChart.leftAxis.drawGridLinesEnabled = chartFlag
        scatterChart.rightAxis.drawGridLinesEnabled = chartFlag
        
        scatterChart.xAxis.drawAxisLineEnabled = chartFlag
        scatterChart.leftAxis.drawAxisLineEnabled = chartFlag
        scatterChart.rightAxis.drawAxisLineEnabled = chartFlag
        
        scatterChart.xAxis.centerAxisLabelsEnabled = chartFlag
        scatterChart.leftAxis.centerAxisLabelsEnabled = chartFlag
        scatterChart.rightAxis.centerAxisLabelsEnabled = chartFlag

        scatterChart.xAxis.drawLabelsEnabled = chartFlag
        scatterChart.leftAxis.drawLabelsEnabled = chartFlag
        scatterChart.rightAxis.drawLabelsEnabled = chartFlag
        
        scatterChart.legend.enabled = chartFlag
        
        scatterChart.backgroundColor = .clear
        
        scatterChart.data = chartData
    }
    
    internal func configure(cardData: CardItemData, RP: [String: [[Double]]], chartLimits: [String: [Double]], flag: Bool) {
        self.cardData = cardData
        self.sectorID = cardData.sector_id
        self.buildings = cardData.infoBuilding
        self.levels = cardData.infoLevel
        self.RP = RP
        self.chartLimits = chartLimits
        self.flagRP = flag
        
        setDropDown()
    }
    
    func updateCoord(data: CoordToDisplay, flag: Bool) {
        self.XY[0] = data.x
        self.XY[1] = data.y
        
        if (data.building == "") {
            currentBuilding = buildings[0]
        } else {
            currentBuilding = data.building
            if (data.level == "") {
                currentLevel = levels[currentBuilding]![0]
            } else {
                currentLevel = data.level
            }
        }
        
        fetchLevel(building: currentBuilding, level: currentLevel, flag: flag)
        
        let key = "\(currentBuilding)_\(currentLevel)"
        let condition: ((String, [[Double]])) -> Bool = {
            $0.0.contains(key)
        }
        
        if (RP!.contains(where: condition)) {
            let rp: [[Double]] = RP?[key] ?? [[Double]]()
            
            let limits: [Double] = chartLimits?[key] ?? [0, 0, 0, 0]
            
            if (rp.isEmpty) {
                scatterChart.isHidden = true
            } else {
                scatterChart.isHidden = false
                if (flag) {
                    drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY, limits: limits)
                } else {
                    drawUser(RP_X: rp[0], RP_Y: rp[1], XY: XY, limits: limits)
                }
            }
            
        } else {
            scatterChart.isHidden = false
        }
            
        levelCollectionView.reloadData()
    }
}

extension SectorContainerTableViewCell : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentLevel = levels[currentBuilding]![indexPath.row]
        
        let key = "\(currentBuilding)_\(currentLevel)"
        let rp: [[Double]] = RP?[key] ?? [[Double]]()
        
        let limits: [Double] = chartLimits?[key] ?? [0, 0, 0, 0]
        
        if (rp.isEmpty) {
            // RP가 없어서 그리지 않음
            scatterChart.isHidden = true
        } else {
            scatterChart.isHidden = false
            if (flagRP) {
                drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY, limits: limits)
            } else {
                drawUser(RP_X: rp[0], RP_Y: rp[1], XY: XY, limits: limits)
            }
            
            fetchLevel(building: currentBuilding, level: currentLevel, flag: flagRP)
        }
        
        levelCollectionView.reloadData()
    }
    
}

extension SectorContainerTableViewCell : UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        levels[currentBuilding]!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let levelCollectionView = collectionView.dequeueReusableCell(withReuseIdentifier: LevelCollectionViewCell.className, for: indexPath)
                as? LevelCollectionViewCell else {return UICollectionViewCell()}

        levelCollectionView.setName(level: levels[currentBuilding]![indexPath.row],
                                    isClicked: currentLevel == levels[currentBuilding]![indexPath.row] ? true : false)
        fetchLevel(building: currentBuilding, level: currentLevel, flag: flagRP)
        
        levelCollectionView.layer.cornerRadius = 15
        levelCollectionView.layer.borderColor = UIColor.blue1.cgColor
        levelCollectionView.layer.borderWidth = 1
        
        return levelCollectionView
    }
}

extension SectorContainerTableViewCell : UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.text = levels[currentBuilding]![indexPath.row]
        label.sizeToFit()
        
        return CGSize(width: label.frame.width + 30, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
}

extension SectorContainerTableViewCell: CustomSwitchButtonDelegate {
    func isOnValueChange(isOn: Bool) {
        self.modeAuto = isOn
    }
}
