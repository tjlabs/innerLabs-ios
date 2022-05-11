//
//  MapViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/09.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import ExpyTableView
import Charts

enum TableList{
    case sector
}

protocol PageDelegate {
    func sendPage(data: Int)
}

enum ContainerTableViewState {
    case expanded
    case normal
}

class MapViewController: UIViewController, ExpyTableViewDelegate, ExpyTableViewDataSource {
    
    @IBOutlet var MapView: UIView!
    
    @IBOutlet weak var jupiterTableView: UITableView!
    @IBOutlet weak var jupiterTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var containerTableView: ExpyTableView!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    
    private let tableList: [TableList] = [.sector]
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    var jupiterService = JupiterService()
    var uuid: String = ""
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
    var delegate : PageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    var referencePoints = [[Double]]()
    var rpX = [Double]()
    var rpY = [Double]()
    
    var RP = [String: [[Double]]]()
    
    var isShow: Bool = false
    var isRadioMap: Bool = false
    
    // View
    var defaultHeight: CGFloat = 100
    
    // Test
    let arraySection0: Array<String> = ["section0_row0","section0_row1","section0_row2"]
    let arraySection1: Array<String> = ["section1_row0","section1_row1","section1_row2","section1_row3"]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setCardData(cardData: cardData!)
        
        if (cardData?.sectorID == 2) {
            let numLevels: Int = (cardData?.infoLevel.count)!
            for idx in 0..<numLevels {
                if (idx == 0) {
                    loadRP(fileName: "Autoway_RP_B4F")
                } else {
                    loadRP(fileName: "Autoway_RP_B3F")
                }
                let nameLevel: String = (cardData?.infoLevel[idx])!
                RP[nameLevel] = [rpX, rpY]
            }
            isRadioMap = true
        }
        
        makeDelegate()
        registerXib()
        fixChartHeight(flag: isRadioMap)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        jupiterService.uuid = uuid
        jupiterService.startService(parent: self)
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
            showContainerTableView()
        }
        else {
            isShow = false
            hideContainerTableView()
        }
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorNameLabel.text = cardData.name
        self.cardTopImage.image = UIImage(named: cardData.cardTopImage)!
    }
    
    func showContainerTableView() {
        containerViewHeight.constant = 220
    }
    
    func hideContainerTableView() {
        containerViewHeight.constant = defaultHeight
    }
    
    func fixChartHeight(flag: Bool) {
        if (flag) {
            let xMin = rpX.min()!
            let xMax = rpX.max()!
            let yMin = rpY.min()!
            let yMax = rpY.max()!
            
            let ratio = (yMax - yMin) / (xMax - xMin)
            jupiterTableViewHeight.constant = jupiterTableView.bounds.width * ratio

            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
            
            defaultHeight = MapView.bounds.height - 120 - jupiterTableViewHeight.constant - bottomPadding
            
            containerViewHeight.constant = defaultHeight
        } else {
            jupiterTableViewHeight.constant = 480
            containerViewHeight.constant = 150
        }
    }
    
    func registerXib() {
        let sectorContainerTVC = UINib(nibName: SectorContainerTableViewCell.identifier, bundle: nil)
        jupiterTableView.register(sectorContainerTVC, forCellReuseIdentifier: SectorContainerTableViewCell.identifier)
        jupiterTableView.backgroundColor = .systemGray6
    }
    
    func makeDelegate() {
        jupiterTableView.dataSource = self
        jupiterTableView.delegate = self
        jupiterTableView.bounces = false
        
        containerTableView.dataSource = self
        containerTableView.delegate = self
        containerTableView.bounces = false
    }
    
    func setTableView() {
        //테이블 뷰 셀 사이의 회색 선 없애기
        jupiterTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        containerTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    private func parseCSV(url:URL) {
        do {
            let data = try Data(contentsOf: url)
            let dataEncoded = String(data: data, encoding: .utf8)
            
            if let dataArr = dataEncoded?.components(separatedBy: "\n").map({$0.components(separatedBy: ",")}) {
                for item in dataArr {
                    let rp: [String] = item
                    if(rp.count == 2) {
                        let x = rp[0]
                        let y = rp[1].components(separatedBy: "\r")
                        
                        rpX.append(Double(x)!)
                        rpY.append(Double(y[0])!)
                    }
                }
            }
        } catch {
            print("Error reading CSV file")
            
        }
    }
    
    private func loadRP(fileName: String) {
        let path = Bundle.main.path(forResource: fileName, ofType: "csv")!
        parseCSV(url: URL(fileURLWithPath: path))
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
//        cell.backgroundColor = .systemGray6 //백그라운드 컬러
        cell.backgroundColor = .white
        cell.selectionStyle = .none //선택했을 때 회색되는거 없애기
        cell.separatorInset = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
        if section == 0 {
            cell.textLabel?.text = "Service Information"
            cell.textLabel?.font = UIFont(name: AppFontName.bold, size: 16)
        } else {
            cell.textLabel?.text = "Robot"
            cell.textLabel?.font = UIFont(name: AppFontName.bold, size: 16)
            
        }
        return cell
    }
}


extension MapViewController: UITableViewDelegate {
    // 높이 지정 index별
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (tableView == jupiterTableView) {
            return jupiterTableView.frame.height
            //        return UITableView.automaticDimension
        } else {
            if indexPath.row == 0 {
                return 40
            } else {
                return 60
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (tableView == jupiterTableView) {
            return 1
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView == jupiterTableView) {
            
        } else {
            print("\(indexPath.section)섹션 \(indexPath.row)로우 선택됨")
        }
    }
}

extension MapViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == jupiterTableView) {
            return tableList.count
        } else {
            if section == 0 {
//                return arraySection0.count
                return 1
            } else {
                return arraySection1.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView == jupiterTableView) {
            let tableList = tableList[indexPath.row]
            switch(tableList) {
            case .sector:
                guard let sectorContainerTVC = tableView.dequeueReusableCell(withIdentifier: SectorContainerTableViewCell.identifier) as?
                        SectorContainerTableViewCell else {return UITableViewCell()}
                sectorContainerTVC.configure(cardData: cardData!, RP: RP)
                sectorContainerTVC.selectionStyle = .none
                
                return sectorContainerTVC
            }
        } else {
            if indexPath.section == 0 {
//                cell.textLabel?.text = arraySection0[indexPath.row]
                
                guard let serviceInfoTVC = tableView.dequeueReusableCell(withIdentifier: ServiceInfoTableViewCell.identifier) as?
                        ServiceInfoTableViewCell else { return UITableViewCell() }
                return serviceInfoTVC
            } else {
                let cell = UITableViewCell()
                cell.textLabel?.text = arraySection1[indexPath.row]
                return cell
            }
        }
    }
}
