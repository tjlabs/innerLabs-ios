//
//  MapContainerTableViewCell.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/03/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class SectorContainerTableViewCell: UITableViewCell {
    static let identifier = "SectorContainerTableViewCell"
    
    @IBOutlet weak var zoneCollectionView: UICollectionView!
    @IBOutlet weak var zoneImage: UIImageView!
    
    private let zoneList = DataModel.Zone.getZoneList()
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setCells() {
        ZoneCollectionViewCell.register(target: zoneCollectionView)
    }
    
    private func setZoneCollectionView() {
        zoneCollectionView.delegate = self
        zoneCollectionView.dataSource = self
        zoneCollectionView.reloadData()
    }
    
    private func fetchZone(zone : DataModel.ZoneList) -> Void {
        switch(zone) {
        case .first:
            print("1st floor")
            zoneImage.image = UIImage(named: "floor1")
        case .second:
            print("2nd floor")
            zoneImage.image = UIImage(named: "floor2")
        case .third:
            print("3rd floor")
            zoneImage.image = UIImage(named: "floor3")
        }
        zoneImage.alpha = 0.5
//        configureChartView()
    }
    
}

extension SectorContainerTableViewCell : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        makeVibrate()
        currentZone = zoneList[indexPath.row].case
        zoneCollectionView.reloadData()
    }
    
}

extension SectorContainerTableViewCell : UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        zoneList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let zoneCollectionView = collectionView.dequeueReusableCell(withReuseIdentifier: ZoneCollectionViewCell.className, for: indexPath)
                as? ZoneCollectionViewCell else {return UICollectionViewCell()}
        zoneCollectionView.setName(floor: zoneList[indexPath.row].case.rawValue,
                                    isClicked: currentZone == zoneList[indexPath.row].case ? true : false)
        zoneCollectionView.layer.cornerRadius = 15
        zoneCollectionView.layer.borderColor = UIColor.blue1.cgColor
        zoneCollectionView.layer.borderWidth = 1
        
        return zoneCollectionView
    }
}

extension SectorContainerTableViewCell : UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.text = zoneList[indexPath.row].case.rawValue
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
