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

class SectorContainerTableViewCell: UITableViewCell {
    
    static let identifier = "SectorContainerTableViewCell"
    
    @IBOutlet weak var levelCollectionView: UICollectionView!

    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    var cardData: CardItemData?
    var RP: [String: [[Double]]]?
    var XY: [Double] = [0, 0]

    private var levelList = [String]()
    private var currentLevel: String = ""
    private var countLevelChanged: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setCells()
        setZoneCollectionView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    private func setCells() {
        LevelCollectionViewCell.register(target: levelCollectionView)
    }
    
    private func setZoneCollectionView() {
        levelCollectionView.delegate = self
        levelCollectionView.dataSource = self

        levelCollectionView.reloadData()
    }
    
    private func fetchLevel(currentLevel: String, levelList: [String]) -> Void {
        let arr = levelList
        let idx = (arr.firstIndex(where: {$0 == currentLevel}) ?? 0)
        
        let level: String = levelList[idx]
        imageLevel.image = UIImage(named: level)
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
            scatterChart.leftAxis.axisMinimum = yMin-39
            scatterChart.leftAxis.axisMaximum = yMax+38
        }
        else if (currentLevel == "B3") {
            scatterChart.xAxis.axisMinimum = xMin-4.2
            scatterChart.xAxis.axisMaximum = xMax+1.4
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+3.2
        } else if (currentLevel == "B4") {
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+25.5
        } else {
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax+10
            scatterChart.leftAxis.axisMinimum = yMin
            scatterChart.leftAxis.axisMaximum = yMax
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
        set1.setColor(ChartColorTemplates.colorful()[2])
        set1.scatterShapeSize = 15
        
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
            scatterChart.leftAxis.axisMinimum = yMin-39
            scatterChart.leftAxis.axisMaximum = yMax+38
        }
        else if (currentLevel == "B3") {
            scatterChart.xAxis.axisMinimum = xMin-4.2
            scatterChart.xAxis.axisMaximum = xMax+1.4
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+3.2
        } else if (currentLevel == "B4") {
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+25.5
        } else {
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax+10
            scatterChart.leftAxis.axisMinimum = yMin
            scatterChart.leftAxis.axisMaximum = yMax
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
    
    private func drawTest() {
        
        let randomNumX = Double.random(in: 10...40)
        let randomNumY = Double.random(in: 10...40)
        
        let values1 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: randomNumX, y: randomNumY)
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "TEST")
        set1.setScatterShape(.circle)
        set1.setColor(ChartColorTemplates.colorful()[2])
        set1.scatterShapeSize = 15
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.setDrawValues(false)
        
        let chartFlag: Bool = false
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
    
    internal func configure(cardData: CardItemData, RP: [String: [[Double]]]) {
        self.cardData = cardData
        self.levelList = (cardData.infoLevel)
        self.RP = RP
    }
    
    func updateCoord(data: CoordToDisplay) {
        self.XY[0] = data.x
        self.XY[1] = data.y
        
//        print("XY :", self.XY[0] , ",", self.XY[1])
        
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
            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY)
//            drawUser(RP_X: rp[0], RP_Y: rp[1], XY: XY)
        } else {
            drawTest()
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
//            drawTest()
        } else {
            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY)
//            drawUser(RP_X: rp[0], RP_Y: rp[1], XY: XY)
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
