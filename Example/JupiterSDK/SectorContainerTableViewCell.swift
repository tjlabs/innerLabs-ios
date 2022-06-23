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
import DropDown

class SectorContainerTableViewCell: UITableViewCell {
    
    static let identifier = "SectorContainerTableViewCell"
    
    @IBOutlet weak var levelCollectionView: UICollectionView!

    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    // DropDown
    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var dropImage: UIImageView!
    @IBOutlet weak var dropText: UITextField!
    @IBOutlet weak var dropButton: UIButton!
    
    let dropDown = DropDown()
    
    var cardData: CardItemData?
    var RP: [String: [[Double]]]?
    var XY: [Double] = [0, 0]
    var flagRP: Bool = false

    private var buildingList = [String]()
    private var levelList = [String]()
    private var currentLevel: String = ""
    private var countLevelChanged: Int = 0
    
    var sectorID: Int = 0
    var building: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setCells()
        setLevelCollectionView()
        
        initDropDown()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    private func initDropDown() {
        dropView.layer.cornerRadius = 6
        
        DropDown.appearance().textColor = UIColor.black // 아이템 텍스트 색상
        DropDown.appearance().selectedTextColor = UIColor.red // 선택된 아이템 텍스트 색상
        DropDown.appearance().backgroundColor = UIColor.white // 아이템 팝업 배경 색상
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGray // 선택한 아이템 배경 색상
        DropDown.appearance().setupCornerRadius(6)
        
        dropText.borderStyle = .none
//        dropText.text = "Buildings"
        
        dropDown.dismissMode = .automatic // 팝업을 닫을 모드 설정
    }
    
    private func setDropDown() {
        dropDown.dataSource = self.buildingList
        
        // anchorView를 통해 UI와 연결
        dropDown.anchorView = self.dropView
            
        // View를 갖리지 않고 View아래에 Item 팝업이 붙도록 설정
        dropDown.bottomOffset = CGPoint(x: 0, y: dropView.bounds.height)
            
        // Item 선택 시 처리
        dropDown.selectionAction = { [weak self] (index, item) in
            //선택한 Item을 TextField에 넣어준다.
            self!.dropText.text = item
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
    
    private func fetchLevel(currentLevel: String, levelList: [String]) -> Void {
        let arr = levelList
        let idx = (arr.firstIndex(where: {$0 == currentLevel}) ?? 0)
        
        let level: String = levelList[idx]
        imageLevel.image = UIImage(named: level)
//        print("Width :", imageLevel.image!.size.width)
//        print("Height :", imageLevel.image!.size.height)
        
//        guard let urlLevel = URL(string: "https://storage.googleapis.com/jupiter_image/map/\(sectorID)/\(building)_\(level).png") else {
//            return nil
//        }
        
//        let resourceLevel = ImageResource(downloadURL: urlSector!, cacheKey: "\(sectorName)Main")
//        cell.sectorImageView.kf.setImage(with: urlLevel, placeholder: nil, options: [.transition(.fade(1.2))], completionHandler: nil)
    }
    
    private func drawRP(RP_X: [Double], RP_Y: [Double], XY: [Double]) {
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
        set1.scatterShapeSize = 4
        
        let set2 = ScatterChartDataSet(entries: values2, label: "User")
        set2.drawValuesEnabled = false
        set2.setScatterShape(.circle)
        set2.setColor(UIColor.systemRed)
        set2.scatterShapeSize = 16
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        let chartFlag: Bool = false
        
        // Configure Chart
        if (currentLevel == "B1") {
            scatterChart.xAxis.axisMinimum = xMin-6
            scatterChart.xAxis.axisMaximum = xMax+9.5
            scatterChart.leftAxis.axisMinimum = yMin-40
            scatterChart.leftAxis.axisMaximum = yMax+38.5
        }
        else if (currentLevel == "B2") {
            scatterChart.xAxis.axisMinimum = xMin-28
            scatterChart.xAxis.axisMaximum = xMax+12
            scatterChart.leftAxis.axisMinimum = yMin-2
            scatterChart.leftAxis.axisMaximum = yMax+39.5
        }
        else if (currentLevel == "B3") {
            scatterChart.xAxis.axisMinimum = xMin-3.8
            scatterChart.xAxis.axisMaximum = xMax+6
            scatterChart.leftAxis.axisMinimum = yMin-11.3
            scatterChart.leftAxis.axisMaximum = yMax+1.5
        } else if (currentLevel == "B4") {
            scatterChart.xAxis.axisMinimum = xMin-9
            scatterChart.xAxis.axisMaximum = xMax
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+25.5
        } else {
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax+10
            scatterChart.leftAxis.axisMinimum = yMin-10
            scatterChart.leftAxis.axisMaximum = yMax+10
        }
        
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
    
    private func drawUser(RP_X: [Double], RP_Y: [Double], XY: [Double]) {
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
        if (currentLevel == "B1") {
            scatterChart.xAxis.axisMinimum = xMin-6
            scatterChart.xAxis.axisMaximum = xMax+9.5
            scatterChart.leftAxis.axisMinimum = yMin-40
            scatterChart.leftAxis.axisMaximum = yMax+38.5
        } else if (currentLevel == "B2") {
            scatterChart.xAxis.axisMinimum = xMin-28
            scatterChart.xAxis.axisMaximum = xMax+12
            scatterChart.leftAxis.axisMinimum = yMin-2
            scatterChart.leftAxis.axisMaximum = yMax+39.5
        } else if (currentLevel == "B3") {
            scatterChart.xAxis.axisMinimum = xMin-3.8
            scatterChart.xAxis.axisMaximum = xMax+6
            scatterChart.leftAxis.axisMinimum = yMin-11.3
            scatterChart.leftAxis.axisMaximum = yMax+1.5
        } else if (currentLevel == "B4") {
            scatterChart.xAxis.axisMinimum = xMin-9
            scatterChart.xAxis.axisMaximum = xMax
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+25.5
        } else {
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax+10
            scatterChart.leftAxis.axisMinimum = yMin-10
            scatterChart.leftAxis.axisMaximum = yMax+10
        }
        
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
    
    internal func configure(cardData: CardItemData, RP: [String: [[Double]]], flag: Bool) {
        self.cardData = cardData
        self.buildingList = cardData.infoBuilding
        self.levelList = (cardData.infoLevel)
        self.RP = RP
        self.flagRP = flag
        
        setDropDown()
    }
    
    func updateCoord(data: CoordToDisplay, flag: Bool) {
        self.XY[0] = data.x
        self.XY[1] = data.y
        
        if (data.level == "") {
            currentLevel = levelList[0]
        } else {
            currentLevel = data.level
        }
        fetchLevel(currentLevel: currentLevel, levelList: levelList)
        
        let condition: ((String, [[Double]])) -> Bool = {
            $0.0.contains(self.currentLevel)
        }
        
        if (RP!.contains(where: condition)) {
            let rp: [[Double]] = RP?[currentLevel] ?? [[Double]]()
            
            if (rp.isEmpty) {
                scatterChart.alpha = 0
            } else {
                scatterChart.alpha = 1.0
                if (flag) {
                    drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY)
                } else {
                    drawUser(RP_X: rp[0], RP_Y: rp[1], XY: XY)
                }
            }
            
        } else {
            scatterChart.alpha = 1.0
        }
            
        levelCollectionView.reloadData()
    }
}

extension SectorContainerTableViewCell : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        makeVibrate()
        currentLevel = levelList[indexPath.row]
        
        let rp: [[Double]] = RP?[currentLevel] ?? [[Double]]()
        if (rp.isEmpty) {
            // RP가 없어서 그리지 않음
            scatterChart.alpha = 0
        } else {
            scatterChart.alpha = 1.0
            if (flagRP) {
                drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY)
            } else {
                drawUser(RP_X: rp[0], RP_Y: rp[1], XY: XY)
            }
            
            fetchLevel(currentLevel: currentLevel, levelList: levelList)
        }
        
        levelCollectionView.reloadData()
    }
    
}

extension SectorContainerTableViewCell : UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        levelList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let levelCollectionView = collectionView.dequeueReusableCell(withReuseIdentifier: LevelCollectionViewCell.className, for: indexPath)
                as? LevelCollectionViewCell else {return UICollectionViewCell()}

        levelCollectionView.setName(level: levelList[indexPath.row],
                                    isClicked: currentLevel == levelList[indexPath.row] ? true : false)
        fetchLevel(currentLevel: currentLevel, levelList: levelList)
        
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
        label.text = levelList[indexPath.row]
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
