//
//  MapViewController.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/09.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import JupiterSDK
import Alamofire
import ExpyTableView
import Charts
import SwiftUI

protocol MapViewPageDelegate {
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
    
    var delegate : MapViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    var referencePoints = [[Double]]()
    
    var RP = [String: [[Double]]]()
    var chartLimits = [String: [Double]]()
    
    var pastX: Double = 0
    var pastY: Double = 0
    
    var numLevels: Int = 0
    var infoOfLevels: String = ""
    var runMode: String = ""
    
    var buildings = [String]()
    var currentBuilding: String = ""
    var levels = [String:[String]]()
    
    var levelList = [String]()
    var currentLevel: String = ""
    
    var isShow: Bool = false
    var isRadioMap: Bool = false
    var isOpen: Bool = false
    
    var coordToDisplay = CoordToDisplay()
    var resultToDisplay = ResultToDisplay()
    
    var isShowRP = false
    var countTap: Int = 0
    
    // View
    var defaultHeight: CGFloat = 100
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setCardData(cardData: cardData!)
        makeDelegate()
        registerXib()
        
        if (cardData?.sector_id != 0 && cardData?.sector_id != 7) {
            let firstBuilding: String = (cardData?.infoBuilding[0])!
            let firstBuildingLevels: [String] = (cardData?.infoLevel[firstBuilding])!
            
            displayLevelInfo(infoLevel: firstBuildingLevels)
            
            levelList = firstBuildingLevels
            
            isRadioMap = true
        } else {
            isRadioMap = false
        }
        
        fixChartHeight(flag: isRadioMap)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runMode = cardData!.mode
        
        // Jupiter Service
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
        
        self.sectorNameLabel.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(self.showRP))
        self.sectorNameLabel.addGestureRecognizer(tapRecognizer)
        
        self.buildings = cardData.infoBuilding
        self.levels = cardData.infoLevel
        
        
        let numBuildings: Int = cardData.infoBuilding.count
        for building in 0..<numBuildings {
            let buildingName: String = cardData.infoBuilding[building]
            let levels: [String] = cardData.infoLevel[buildingName]!
            let numLevels: Int = levels.count

            for level in 0..<numLevels {
                let levelName: String = levels[level]
                
                // Download RP
//                let fileName: String = "\(cardData.sector_id)/\(buildingName)_\(levelName).txt"
//                let rpXY: [[Double]] = downloadRP(fileName: fileName)
                let key: String = "\(buildingName)_\(levelName)"
                let rpXY = loadRP(fileName: key)
                if (!rpXY.isEmpty) {
                    RP[key] = rpXY
                    
                    let xAxisValue: [Double] = rpXY[0]
                    let yAxisValue: [Double] = rpXY[1]
                    
                    let xMin = xAxisValue.min()!
                    let xMax = xAxisValue.max()!
                    let yMin = yAxisValue.min()!
                    let yMax = yAxisValue.max()!
                    
                    print("(\(key)) Min Max : [\(xMin), \(xMax), \(yMin), \(yMax)]")
                }
                
                // Scale
                let input = Scale(sector_id: cardData.sector_id, building_name: buildingName, level_name: levelName)
                Network.shared.postScale(url: SCALE_URL, input: input, completion: { [self] statusCode, returnedString in
                    let result = jsonToScale(json: returnedString)
                    
                    if (statusCode >= 200 && statusCode <= 300) {
                        let scaleString = result.image_scale
                        
                        if (scaleString.isEmpty) {
                            chartLimits[key] = [0, 0, 0, 0]
                        } else {
                            let os = scaleString.components(separatedBy: "/")
                            let arr = os[1].components(separatedBy: " ")
                            var data = [Double]()
                            
                            for i in 0..<arr.count {
                                data.append(Double(arr[i])!)
                            }
                            chartLimits[key] = data
                        }
                    }
                })
            }
        }
    }
    
    func displayLevelInfo(infoLevel: [String]) {
        let numLevels = infoLevel.count
        
        if (infoLevel.isEmpty) {
            infoOfLevels = ""
            self.numLevels = 0
        } else {
            let firstLevel: String = infoLevel[0]
            
            if (numLevels == 1) {
                infoOfLevels = "( " + firstLevel + " )"
            } else {
                let lastLevel: String = infoLevel[numLevels-1]
                infoOfLevels = "( " + firstLevel + "~" + lastLevel + " )"
            }
            
            self.numLevels = numLevels
        }
        
    }
    
    @objc func showRP() {
        countTap += 1
        
        if (countTap == 5) {
            isShowRP = true
            self.sectorNameLabel.textColor = .yellow
        } else if (countTap > 9) {
            isShowRP = false
            countTap = 0
            self.sectorNameLabel.textColor = .white
        }
    }
    
    func showContainerTableView() {
        containerViewHeight.constant = 220
    }
    
    func hideContainerTableView() {
        containerViewHeight.constant = defaultHeight
    }
    
    func fixChartHeight(flag: Bool) {
        if (flag) {
            if ( cardData?.sector_id == 1 || cardData?.sector_id == 2 ) {
                jupiterTableViewHeight.constant = 480
                containerViewHeight.constant = 150
            } else if ( cardData?.sector_id == 3 || cardData?.sector_id == 4 || cardData?.sector_id == 5 || cardData?.sector_id == 6 ) {
                let ratio: Double = 114900 / 68700
                jupiterTableViewHeight.constant = jupiterTableView.bounds.width * ratio

                let window = UIApplication.shared.keyWindow
                let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                
                defaultHeight = MapView.bounds.height - 100 - jupiterTableViewHeight.constant - bottomPadding
                
                containerViewHeight.constant = defaultHeight
            }
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
    
    private func loadRP(fileName: String) -> [[Double]] {
        let path = Bundle.main.path(forResource: fileName, ofType: "csv")!
        let rpXY:[[Double]] = parseRP(url: URL(fileURLWithPath: path))
        
        return rpXY
    }
    
    private func downloadRP(fileName: String) -> [[Double]] {
        var rpXY = [[Double]]()
        
        let url = "https://storage.cloud.google.com/jupiter_image/rp/ios/\(fileName)"
        print("Download URL :", url)
        // 파일매니저
        let fileManager = FileManager.default
        // 앱 경로
        let appURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // 파일이름 url 의 맨 뒤 컴포넌트로 지정 (50MB.zip)
        let fileName : String = URL(string: url)!.lastPathComponent
        // 파일 경로 생성
        let fileURL = appURL.appendingPathComponent(fileName)
        // 파일 경로 지정 및 다운로드 옵션 설정 ( 이전 파일 삭제 , 디렉토리 생성 )
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        // 다운로드 시작
        AF.download(url, method: .get, parameters: nil, encoding: JSONEncoding.default, to: destination).downloadProgress { (progress) in
        }.response{ [self] response in
            if response.error != nil {
                print("파일다운로드 실패")
            } else{
                print("파일다운로드 완료 :", fileURL)
                
                if (fileManager.fileExists(atPath: fileURL.path)) {
                    // File 존재
                    rpXY = parseRP(url: URL(fileURLWithPath: fileURL.path))
                }
            }
        }
        return rpXY
    }
    
    private func parseRP(url:URL) -> [[Double]] {
        print("Parsing :", url)
        
        var rpXY = [[Double]]()
        
        var rpX = [Double]()
        var rpY = [Double]()
        
        do {
            let data = try Data(contentsOf: url)
            let dataEncoded = String(data: data, encoding: .utf8)
            
            if let dataArr = dataEncoded?.components(separatedBy: "\n").map({$0.components(separatedBy: ",")}) {
                for item in dataArr {
                    let rp: [String] = item
                    if (rp.count == 2) {
                        
                        guard let x: Double = Double(rp[0]) else { return [[Double]]() }
                        guard let y: Double = Double(rp[1].components(separatedBy: "\r")[0]) else { return [[Double]]() }
                        
                        rpX.append(x)
                        rpY.append(y)
                    }
                }
            }
            rpXY = [rpX, rpY]
        } catch {
            print("Error reading .csv file")
        }
        
        return rpXY
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
        let unitLength = jupiterService.unitDistane
        let status = jupiterService.unitDRInfo.lookingFlag

        if (isStepDetected) {
            let buildingName: String = jupiterService.jupiterOutput.building
            let buildingLevels: [String] = cardData!.infoLevel[buildingName] ?? []
            displayLevelInfo(infoLevel: buildingLevels)

            resultToDisplay.unitIndexTx = unitIdxTx
            resultToDisplay.unitLength = unitLength
            resultToDisplay.phase = String(status)

            let x = jupiterService.jupiterOutput.x
            let y = jupiterService.jupiterOutput.y

            let building = jupiterService.jupiterOutput.building
            let level = jupiterService.jupiterOutput.level

            var levelOutput: String = ""

            if (buildings.contains(building)) {
                if let levelList: [String] = levels[building] {
                    if (levelList.contains(level)) {
                        levelOutput = level
                    } else {
                        levelOutput = "Out of bounds"
                    }
                } else {
                    levelOutput = "Out of bounds"
                }
            } else {
                levelOutput = "Out of bounds"
            }

            let unitIdxRx = jupiterService.jupiterOutput.index
            let scc = jupiterService.jupiterOutput.scc

            coordToDisplay.x = x
            coordToDisplay.y = y
            coordToDisplay.building = building
            coordToDisplay.level = levelOutput

            resultToDisplay.unitIndexRx = unitIdxRx
            resultToDisplay.level = levelOutput
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
    
    func jsonToScale(json: String) -> ScaleResponse {
        let result = ScaleResponse(image_scale: "")
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(ScaleResponse.self, from: data) {
            return decoded
        }

        return result
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
    
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
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
        cell.backgroundColor = .systemGray6
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
                    return 220 + 20
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
//            print("\(indexPath.section)섹션 \(indexPath.row)로우 선택됨")
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
                
                sectorContainerTVC.backgroundColor = .systemGray6
                sectorContainerTVC.configure(cardData: cardData!, RP: RP, chartLimits: chartLimits, flag: isShowRP)
                
                if (cardData?.sector_id != 0 && cardData?.sector_id != 7) {
                    sectorContainerTVC.updateCoord(data: coordToDisplay, flag: isShowRP)
                }
                
                sectorContainerTVC.selectionStyle = .none
                
                return sectorContainerTVC
            }
        } else {
            if indexPath.section == 0 {
                let serviceInfoTVC = tableView.dequeueReusableCell(withIdentifier: ServiceInfoTableViewCell.identifier) as!
                ServiceInfoTableViewCell
                
                serviceInfoTVC.backgroundColor = .systemGray6
                serviceInfoTVC.infoOfLevelsLabel.text = infoOfLevels
                serviceInfoTVC.numberOfLevelsLabel.text = String(numLevels)
                serviceInfoTVC.modeLabel.text = runMode
                
                serviceInfoTVC.updateResult(data: resultToDisplay)
                
                return serviceInfoTVC
            } else {
                let robotTVC = tableView.dequeueReusableCell(withIdentifier: RobotTableViewCell.identifier) as!
                RobotTableViewCell
                
                robotTVC.backgroundColor = .systemGray6
                
                return robotTVC
            }
        }
    }
}
