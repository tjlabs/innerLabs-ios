//
//  MapContainerTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/03/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import Charts

class SectorContainerTableViewCell: UITableViewCell {
    static let identifier = "SectorContainerTableViewCell"
    
    
    @IBOutlet weak var levelCollectionView: UICollectionView!
    @IBOutlet weak var zoneImage: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    var rpX: [Double] = []
    var rpY: [Double] = []
    
    private let levelList = DataModel.Zone.getZoneList()
    private var currentZone : DataModel.ZoneList = .first{
        didSet {
            fetchZone(zone: currentZone)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setCells()
        setZoneCollectionView()
        fetchZone(zone: currentZone)
        
        configureChartView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setCells() {
        LevelCollectionViewCell.register(target: levelCollectionView)
    }
    
    private func setZoneCollectionView() {
        levelCollectionView.delegate = self
        levelCollectionView.dataSource = self
        levelCollectionView.reloadData()
    }
    
    private func fetchZone(zone : DataModel.ZoneList) -> Void {
        switch(zone) {
        case .first:
            print("1st floor")
//            zoneImage.image = UIImage(named: "floor1")
        case .second:
            print("2nd floor")
//            zoneImage.image = UIImage(named: "floor2")
        case .third:
            print("3rd floor")
//            zoneImage.image = UIImage(named: "floor3")
        }
//        zoneImage.alpha = 0.5
//        configureChartView()
    }
    
    private func drawRP(X: [Double], Y: [Double]) {
//        var entries: [BarChartDataEntry]
        
        let len = X.count
    }
    
    private func configureChartView() {
        let randomNum = Double.random(in: 0...20)
        let xAxisValue: [Double] = [21.7 + randomNum, 22.2 - randomNum]
        let yAxisValue: [Double] = [15.5 + randomNum, 15.2 - randomNum]
        
        let xAxisValue2: [Double] = [10 + randomNum, 24 - randomNum]
        let yAxisValue2: [Double] = [7 + randomNum, 11 - randomNum]

        let values1 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: yAxisValue[i], y: xAxisValue[i])
        }
        
        let values2 = (0..<xAxisValue2.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: yAxisValue2[i], y: xAxisValue2[i])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "DS 1")
        set1.setScatterShape(.square)
        set1.setColor(ChartColorTemplates.colorful()[0])
        set1.scatterShapeSize = 8
        
        let set2 = ScatterChartDataSet(entries: values2, label: "DS 2")
        set2.setScatterShape(.square)
        set2.setColor(ChartColorTemplates.colorful()[1])
        set2.scatterShapeSize = 8
//        set2.scatterShapeHoleColor = ChartColorTemplates.colorful()[3]
//        set2.scatterShapeHoleRadius = 3.5
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        scatterChart.data = chartData
    }
    
}

extension SectorContainerTableViewCell : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        makeVibrate()
        currentZone = levelList[indexPath.row].case
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
        levelCollectionView.setName(floor: levelList[indexPath.row].case.rawValue,
                                    isClicked: currentZone == levelList[indexPath.row].case ? true : false)
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
        label.text = levelList[indexPath.row].case.rawValue
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
