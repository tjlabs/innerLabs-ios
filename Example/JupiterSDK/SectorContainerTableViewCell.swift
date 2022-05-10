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

//    private let levelList = DataModel.Zone.getZoneList()
//    private var currentZone : DataModel.ZoneList = .first{
//        didSet {
//            fetchZone(zone: currentZone)
//        }
//    }
    
    private var levelList = [String]()
    private var currentLevel: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setCells()
        setZoneCollectionView()
//        fetchZone(zone: currentZone)
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
    
//    private func fetchZone(zone : DataModel.ZoneList) -> Void {
//        switch(zone) {
//        case .first:
//            print("1st floor")
////            zoneImage.image = UIImage(named: "floor1")
//        case .second:
//            print("2nd floor")
////            zoneImage.image = UIImage(named: "floor2")
//        case .third:
//            print("3rd floor")
////            zoneImage.image = UIImage(named: "floor3")
//        }
////        zoneImage.alpha = 0.5
//    }
    
    private func drawRP(X: [Double], Y: [Double]) {
        let randomNum = Double.random(in: 0...20)
        
        let xAxisValue: [Double] = X
        let yAxisValue: [Double] = Y
        
//        let xAxisValue: [Double] = [21.7 + randomNum, 22.2 - randomNum]
//        let yAxisValue: [Double] = [15.5 + randomNum, 15.2 - randomNum]
        
        let xAxisValue2: [Double] = [10 + randomNum, 24 - randomNum]
        let yAxisValue2: [Double] = [7 + randomNum, 11 - randomNum]

        let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: yAxisValue[i], y: xAxisValue[i])
        }
        
        let values2 = (0..<xAxisValue2.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: yAxisValue2[i], y: xAxisValue2[i])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "RP")
        set1.setScatterShape(.square)
        set1.setColor(ChartColorTemplates.joyful()[4])
        set1.scatterShapeSize = 8
        
        let set2 = ScatterChartDataSet(entries: values2, label: "Random")
        set2.setScatterShape(.square)
        set2.setColor(ChartColorTemplates.colorful()[1])
        set2.scatterShapeSize = 8
//        set2.scatterShapeHoleColor = ChartColorTemplates.colorful()[3]
//        set2.scatterShapeHoleRadius = 3.5
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        // Configure Chart
        scatterChart.xAxis.axisMinimum = yMin-5
        scatterChart.xAxis.axisMaximum = yMax+5
        scatterChart.leftAxis.axisMinimum = xMin-5
        scatterChart.leftAxis.axisMaximum = xMax+5
        
        scatterChart.xAxis.drawGridLinesEnabled = false
        scatterChart.leftAxis.drawGridLinesEnabled = false
        scatterChart.rightAxis.drawGridLinesEnabled = false
        
        scatterChart.xAxis.drawAxisLineEnabled = false
        scatterChart.leftAxis.drawAxisLineEnabled = false
        scatterChart.rightAxis.drawAxisLineEnabled = false
        
        scatterChart.xAxis.centerAxisLabelsEnabled = false
        scatterChart.xAxis.drawLabelsEnabled = false
        
        scatterChart.leftAxis.centerAxisLabelsEnabled = false
        scatterChart.leftAxis.drawLabelsEnabled = false
        
        scatterChart.rightAxis.centerAxisLabelsEnabled = false
        scatterChart.rightAxis.drawLabelsEnabled = false
        
        scatterChart.legend.enabled = false
        
        scatterChart.backgroundColor = .clear
        
        scatterChart.data = chartData
    }
    
    internal func configure(cardData: CardItemData, RP: [String: [[Double]]]) {
        self.cardData = cardData
        self.levelList = (cardData.infoLevel)
        currentLevel = levelList[0]
        
        self.RP = RP
        let rp: [[Double]] = RP[currentLevel] ?? [[Double]]()
        if (rp.isEmpty) {
            // RP가 없어서 그리지 않음
        } else {
            drawRP(X: rp[0], Y: rp[1])
        }
    }
}

extension SectorContainerTableViewCell : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        makeVibrate()
        currentLevel = levelList[indexPath.row]
//        currentZone = levelList[indexPath.row].case
//        fetchZone(zone: currentZone)
        
        let rp: [[Double]] = RP?[currentLevel] ?? [[Double]]()
        if (rp.isEmpty) {
            // RP가 없어서 그리지 않음
        } else {
            drawRP(X: rp[0], Y: rp[1])
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
//        levelCollectionView.setName(level: levelList[indexPath.row].case.rawValue,
//                                    isClicked: currentZone == levelList[indexPath.row].case ? true : false)
        levelCollectionView.setName(level: levelList[indexPath.row],
                                    isClicked: currentLevel == levelList[indexPath.row] ? true : false)
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
//        label.text = levelList[indexPath.row].case.rawValue
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
