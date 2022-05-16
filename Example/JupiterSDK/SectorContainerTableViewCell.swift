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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("Touch Began")
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
        set1.setScatterShape(.square)
        set1.setColor(UIColor.yellow)
        set1.scatterShapeSize = 2
        
        let set2 = ScatterChartDataSet(entries: values2, label: "User")
        set2.setScatterShape(.square)
        set2.setColor(ChartColorTemplates.colorful()[1])
        set2.scatterShapeSize = 8
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        // Configure Chart
        if (currentLevel == "B3") {
//            scatterChart.xAxis.axisMinimum = xMin-4.5
//            scatterChart.xAxis.axisMaximum = xMax+4.5
//            scatterChart.leftAxis.axisMinimum = yMin-11
//            scatterChart.leftAxis.axisMaximum = yMax+2
            
            scatterChart.xAxis.axisMinimum = xMin-4.2
            scatterChart.xAxis.axisMaximum = xMax+1.4
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+3.2
        } else {
//            scatterChart.xAxis.axisMinimum = xMin-15
//            scatterChart.xAxis.axisMaximum = xMax+4.5
//            scatterChart.leftAxis.axisMinimum = yMin-22
//            scatterChart.leftAxis.axisMaximum = yMax+34
            
            scatterChart.xAxis.axisMinimum = xMin-10
            scatterChart.xAxis.axisMaximum = xMax
            scatterChart.leftAxis.axisMinimum = yMin-15
            scatterChart.leftAxis.axisMaximum = yMax+25.5
        }
        
        scatterChart.xAxis.drawGridLinesEnabled = false
        scatterChart.leftAxis.drawGridLinesEnabled = false
        scatterChart.rightAxis.drawGridLinesEnabled = false
        
        scatterChart.xAxis.drawAxisLineEnabled = false
        scatterChart.leftAxis.drawAxisLineEnabled = false
        scatterChart.rightAxis.drawAxisLineEnabled = false
        
        scatterChart.xAxis.centerAxisLabelsEnabled = false
        scatterChart.leftAxis.centerAxisLabelsEnabled = false
        scatterChart.rightAxis.centerAxisLabelsEnabled = false

        scatterChart.xAxis.drawLabelsEnabled = false
        scatterChart.leftAxis.drawLabelsEnabled = false
        scatterChart.rightAxis.drawLabelsEnabled = false
        
        scatterChart.legend.enabled = false
        
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
        
        if (data.level == "") {
            currentLevel = levelList[0]
        } else {
            currentLevel = data.level
        }
        fetchLevel(currentLevel: currentLevel, levelList: levelList)
        
        let rp: [[Double]] = RP?[currentLevel] ?? [[Double]]()
        drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY)
        
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
        } else {
            drawRP(RP_X: rp[0], RP_Y: rp[1], XY: XY)
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
