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


protocol PageDelegate {
    func sendPage(data: Int)
}

enum TableList{
    case sector
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
    
    var numLevels: Int = 0
    var infoOfLevels: String = ""
    var runMode: String = ""
    
    var isShow: Bool = false
    var isRadioMap: Bool = false
    var isOpen: Bool = false
    
    var coordToDisplay = CoordToDisplay()
    var resultToDisplay = ResultToDisplay()
    
    // View
    var defaultHeight: CGFloat = 100
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setCardData(cardData: cardData!)
        makeDelegate()
        registerXib()
        
        if (cardData?.sector_id == 3 || cardData?.sector_id == 4) {
            numLevels = (cardData?.infoLevel.count)!
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
            
            if (numLevels == 1) {
                let first: String = (cardData?.infoLevel[0])!
                infoOfLevels = "( " + first + " )"
            } else {
                let first: String = (cardData?.infoLevel[0])!
                let last: String = (cardData?.infoLevel[numLevels-1])!
                infoOfLevels = "( " + first + "~" + last + " )"
            }
        }
        fixChartHeight(flag: isRadioMap)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (cardData!.mode == 0) {
            runMode = "PDR"
        } else {
            runMode = "DR"
        }
        
        jupiterService.uuid = uuid
        jupiterService.mode = runMode
        jupiterService.startService(parent: self)
        startTimer()
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        jupiterService.stopService()
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
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        self.cardTopImage.image = UIImage(named: imageName)!
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
            
//            let ratio = (yMax - yMin) / (xMax - xMin)
            let ratio: Double = 114900 / 68700
            jupiterTableViewHeight.constant = jupiterTableView.bounds.width * ratio

            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
            
            defaultHeight = MapView.bounds.height - 100 - jupiterTableViewHeight.constant - bottomPadding
            
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
        
        let serviceInfoNib = UINib(nibName: "ServiceInfoTableViewCell", bundle: nil)
        containerTableView.register(serviceInfoNib, forCellReuseIdentifier: "ServiceInfoTableViewCell")
        
        let robotNib = UINib(nibName: "RobotTableViewCell", bundle: nil)
        containerTableView.register(robotNib, forCellReuseIdentifier: "RobotTableViewCell")
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
    
    // Display Outputs
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        
        timerCounter = 0
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
    
    @objc func timerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        
        if (dt < 100) {
            elapsedTime += (dt*1e-3)
        }
        
        // length, scc, status, mode, idx Tx, idx Rx, level
        let isStepDetected = jupiterService.unitDRInfo.isIndexChanged
        
        let unitIdxTx = Int(jupiterService.unitDRInfo.index)
        let unitLength = jupiterService.unitDRInfo.length
        let status = jupiterService.unitDRInfo.lookingFlag
        
        if (isStepDetected) {
            resultToDisplay.unitIndexTx = unitIdxTx
            resultToDisplay.unitLength = unitLength
            resultToDisplay.status = status
            
            let x = jupiterService.jupiterOutput.x
            let y = jupiterService.jupiterOutput.y
            let level = jupiterService.jupiterOutput.level
            let unitIdxRx = jupiterService.jupiterOutput.index
            let scc = jupiterService.jupiterOutput.scc
            
            let randomNumX = Double.random(in: 0...20)
            let randomNumY = Double.random(in: -10...10)
            
            coordToDisplay.x = 30 + randomNumX
            coordToDisplay.y = 50 + randomNumY
            
            coordToDisplay.level = level
            
            resultToDisplay.level = level
            resultToDisplay.unitIndexRx = unitIdxRx
            resultToDisplay.scc = scc
            
            UIView.performWithoutAnimation {
                    self.jupiterTableView.reloadSections(IndexSet(0...0), with: .none)
            }
            if (isOpen) {
                UIView.performWithoutAnimation {
                        self.containerTableView.reloadSections(IndexSet(0...0), with: .none)
                }
            }
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
    
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        print("\(section)섹션")
        
        switch state {
        case .willExpand:
            print("WILL EXPAND")
            if (section == 0) {
               isOpen = true
            }
            
        case .willCollapse:
            print("WILL COLLAPSE")
            if (section == 0) {
                isOpen = false
            }
            
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
        cell.backgroundColor = .white
        cell.selectionStyle = .none //선택했을 때 회색되는거 없애기
        
        cell.separatorInset = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
        if section == 0 {
            cell.textLabel?.text = "  🧑🏻‍🔧 Service Information"
            cell.textLabel?.font = UIFont(name: AppFontName.bold, size: 16)
        } else {
            cell.textLabel?.text = "  🤖 Robot"
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
                if (indexPath.section == 0) {
                    return 300 + 20
                } else {
                    return 120 + 20
                }
                
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
                return 2
            } else {
                return 2
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
                sectorContainerTVC.updateCoord(data: coordToDisplay)
                sectorContainerTVC.selectionStyle = .none
                
                return sectorContainerTVC
            }
        } else {
            if indexPath.section == 0 {
                let serviceInfoTVC = tableView.dequeueReusableCell(withIdentifier: ServiceInfoTableViewCell.identifier) as!
                ServiceInfoTableViewCell
    
                serviceInfoTVC.infoOfLevelsLabel.text = infoOfLevels
                serviceInfoTVC.numberOfLevelsLabel.text = String(numLevels)
                serviceInfoTVC.modeLabel.text = runMode
                
                serviceInfoTVC.updateResult(data: resultToDisplay)
                
                return serviceInfoTVC
            } else {
                let robotTVC = tableView.dequeueReusableCell(withIdentifier: RobotTableViewCell.identifier) as!
                RobotTableViewCell
                
                return robotTVC
            }
        }
    }
}
