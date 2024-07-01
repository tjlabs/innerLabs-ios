//
//  GuideViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/13.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import ExpyTableView
import CoreLocation
import GoogleMaps
import SnapKit

class GuideViewController: UIViewController, ExpyTableViewDelegate, ExpyTableViewDataSource {
    
    @IBOutlet weak var containerMapView: UIView!
    @IBOutlet weak var containerTableView: ExpyTableView!
    @IBOutlet weak var containerTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var infoLabel: UILabel!
    
    
    let lat: Double = 37.49575119345803
    let lon: Double = 127.03829280268539
    
    var delegate : GuideSendPageDelegate?
    var page: Int = 0
    
    var currentRegion: String = ""
    var isShow: Bool = false
    var showInfoText: String = ""
    var closeInfoText: String = ""
    
    var defaultHeight: CGFloat = 100
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locale = Locale.current
        if let countryCode = locale.regionCode, countryCode == "KR" {
            self.currentRegion = "Korea"
        } else {
            self.currentRegion = "Canada"
        }
        self.setTextByRegion(region: self.currentRegion)
        
        configureMapView()
        makeDelegate()
        registerXib()
        self.view.sendSubviewToBack(containerMapView)
    }
    
    
    func configureMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lon, zoom: 18)
        let mapView = GMSMapView.map(withFrame: self.containerMapView.frame, camera: camera)
//        mapView.mapType = GMSMapViewType.satellite
        
        self.view.addSubview(mapView)
        self.view.sendSubviewToBack(mapView)
        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        marker.title = "TJLABS"
        marker.snippet = "Location opens universe"
        marker.map = mapView
    }
    
    func makeDelegate() {
        containerTableView.dataSource = self
        containerTableView.delegate = self
        containerTableView.bounces = false
    }
    
    func registerXib() {
        let guideNib = UINib(nibName: "JupiterGuideTableViewCell", bundle: nil)
        containerTableView.register(guideNib, forCellReuseIdentifier: "JupiterGuideTableViewCell")
        
        let locationNib = UINib(nibName: "LocationTableViewCell", bundle: nil)
        containerTableView.register(locationNib, forCellReuseIdentifier: "LocationTableViewCell")
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
    @IBAction func tapShowButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            isShow = true
            self.infoLabel.text = self.closeInfoText
            showContainerTableView()
        }
        else {
            isShow = false
            self.infoLabel.text = self.showInfoText
            hideContainerTableView()
        }
    }
    
    public func setTextByRegion(region: String) {
        switch (region) {
        case "Korea":
            self.showInfoText = "정보 보기"
            self.closeInfoText = "정보 닫기"
        case "Canada":
            self.showInfoText = "Show"
            self.closeInfoText = "Close"
        default:
            self.showInfoText = "Show"
            self.closeInfoText = "Close"
        }
        
        self.infoLabel.text = self.showInfoText
    }
    
    func showContainerTableView() {
        containerTableViewHeight.constant = 350
    }
    
    func hideContainerTableView() {
        containerTableViewHeight.constant = defaultHeight
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        print("\(section)섹션")
        
        switch state {
        case .willExpand:
            print("WILL EXPAND")
            
        case .willCollapse:
            print("WILL COLLAPSE")
            
        case .didExpand:
            print("DID EXPAND")
            
        case .didCollapse:
            print("DID COLLAPSE")
        }
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .systemGray6
        cell.selectionStyle = .none //선택했을 때 회색되는거 없애기
        
        cell.separatorInset = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
        if section == 0 {
            cell.textLabel?.text = "  💡 Service Guide"
            cell.textLabel?.font = UIFont(name: AppFontName.bold, size: 16)
        } else {
            cell.textLabel?.text = "  📌 About TJLABS"
            cell.textLabel?.font = UIFont(name: AppFontName.bold, size: 16)
            
        }
        return cell
    }
    
}

extension GuideViewController: UITableViewDelegate {
    // 높이 지정 index별
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 40
        } else {
            if (indexPath.section == 0) {
                return 200 + 20
            } else {
                return 200 + 20
            }
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(indexPath.section)섹션 \(indexPath.row)로우 선택됨")
    }
}


extension GuideViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let jupiterGuideTVC = tableView.dequeueReusableCell(withIdentifier: JupiterGuideTableViewCell.identifier) as!
            JupiterGuideTableViewCell
            
            
            jupiterGuideTVC.backgroundColor = .systemGray6
            
            return jupiterGuideTVC
        } else {
            let locationTVC = tableView.dequeueReusableCell(withIdentifier: LocationTableViewCell.identifier) as!
            LocationTableViewCell
            
            locationTVC.backgroundColor = .systemGray6
            
            return locationTVC
        }
        
    }
}
