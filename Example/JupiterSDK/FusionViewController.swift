import UIKit
import JupiterSDK
import Alamofire
import Kingfisher
import ExpyTableView
import Charts
import DropDown
import SwiftUI

class FusionViewController: UIViewController, Observer {
    
    func report(flag: Int) {
        let localTime = getLocalTimeString()
        
        switch(flag) {
        case 0:
            print(localTime + " , (JupiterVC) Report : Stop!! Out of the Service Area")
        case 1:
            print(localTime + " , (JupiterVC) Report : Start!! Enter the Service Area")
        case 2:
            print(localTime + " , (JupiterVC) Report : BLE is Off")
        case -1:
            print(localTime + " , (JupiterVC) Report : Abnormal!! Restart the Service")
        case 3:
            print(localTime + " , (JupiterVC) Report : Start!! Run Venus Mode")
        case 4:
            print(localTime + " , (JupiterVC) Report : Start!! Run Jupiter Mode")
        case 5:
            print(localTime + " , (JupiterVC) Report : Waiting Server Result...")
        case 6:
            print(localTime + " , (JupiterVC) Report : Network Connection Lost")
        case 7:
            print(localTime + " , (JupiterVC) Report : Enter Backgroud")
        case 8:
            print(localTime + " , (JupiterVC) Report : Enter Foreground")
        case 9:
            print(localTime + " , (JupiterVC) Report : Fail to encode RFD")
        case 10:
            print(localTime + " , (JupiterVC) Report : Fail to encode UVD")
        case 11:
            print(localTime + " , (JupiterVC) Report : Fail to scan RFD")
        case 12:
            print(localTime + " , (JupiterVC) Report : Fail to create RFD")
        default:
            print(localTime + " , (JupiterVC) Default Flag")
        }
    }
    
    func update(result: FineLocationTrackingResult) {
        DispatchQueue.main.async {
            let localTime: String = self.getLocalTimeString()
            let dt = result.mobile_time - self.observerTime
            
            let building = result.building_name
            let level = result.level_name
            
            var x = result.x
            var y = result.y
            
            let WINDOW_SIZE = 10
            var isResultTurning = false
            self.resultPosBuffer.append([x, y, result.absolute_heading])
            if (self.resultPosBuffer.count > 10) {
                self.resultPosBuffer.remove(at: 0)
            }
            let resultPhase: Int = result.phase
            if resultPhase == 4 {
                let preX = self.resultPosBuffer[self.resultPosBuffer.count-2][0]
                let preY = self.resultPosBuffer[self.resultPosBuffer.count-2][1]
                let preH = self.resultPosBuffer[0][2]
                
                let diffPos = sqrt((x - preX)*(x - preX) + (y - preY)*(y - preY))
                var diffHeading = result.absolute_heading - preH
                if 270 <= diffHeading &&  diffHeading < 360 {
                    diffHeading = 360 - diffHeading
                }
                if diffPos >= 5 && diffHeading >= 50 {
                    isResultTurning = true
                }
            }
            
            if resultPhase == 4 && !isResultTurning {
                self.averagePosBuffer.append([x, y])
                if (self.averagePosBuffer.count > WINDOW_SIZE) {
                    self.averagePosBuffer.remove(at: 0)
                }
                let avgResult = self.movingAverage(data: self.averagePosBuffer)
                x = avgResult[0]
                y = avgResult[1]
            } else {
                self.averagePosBuffer = [[Double]]()
            }
            
            if (result.ble_only_position) {
                self.isBleOnlyMode = true
            } else {
                self.isBleOnlyMode = false
            }
            //            self.isPathMatchingSuccess = self.serviceManager.displayOutput.isPmSuccess
            //            let log: String = localTime + " , (FusionVC) : dt = \(dt) // time = \(result.mobile_time) // befor = \(self.observerTime) // x = \(result.x) // y = \(result.y) // h = \(result.absolute_heading) // phase = \(result.phase) // Venus = \(result.ble_only_position)"
            //            print(log)
            
            if (self.buildings.contains(building)) {
                if let levelList: [String] = self.levels[building] {
                    if (levelList.contains(level)) {
                        self.coordToDisplay.building = building
                        self.coordToDisplay.level = level
                        self.coordToDisplay.x = x
                        self.coordToDisplay.y = y
                        self.coordToDisplay.heading = result.absolute_heading
                        self.coordToDisplay.isIndoor = result.isIndoor
                    }
                }
            }
            self.observerTime = result.mobile_time
        }
    }
    
    @IBOutlet var fusionView: UIView!
    @IBOutlet weak var cardTopImage: UIImageView!
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var onSpotButton: UIButton!
    
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var displayViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var switchButton: CustomSwitchButton!
    @IBOutlet weak var switchButtonOffset: NSLayoutConstraint!
    
    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var dropImage: UIImageView!
    @IBOutlet weak var dropText: UITextField!
    @IBOutlet weak var dropButton: UIButton!
    
    @IBOutlet weak var levelCollectionView: UICollectionView!
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    @IBOutlet weak var noImageLabel: UILabel!
    
    @IBOutlet weak var mainImage: UIImageView!
    
    
    @IBOutlet weak var spotBuildingLabel: UILabel!
    @IBOutlet weak var spotLevelLabel: UILabel!
    @IBOutlet weak var spotNameLabel: UILabel!
    @IBOutlet weak var spotCcsLabel: UILabel!
    
    private let tableList: [TableList] = [.sector]
    
    var serviceManager = ServiceManager()
    var serviceName = "FLT"
    var region: String = ""
    var uuid: String = ""
    var sector_id: Int = 0
    
    var timer: Timer?
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/10 // second
    
    var pathPixelTimer: DispatchSourceTimer?
    let PP_CHECK_INTERVAL: TimeInterval = 2
    
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
    var delegate : ServiceViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    var RP = [String: [[Double]]]()
    var chartLimits = [String: [Double]]()
    var chartLoad = [String: Bool]()
    
    var XY: [Double] = [0, 0]
    
    var numLevels: Int = 0
    var infoOfLevels: String = ""
    var runMode: String = ""
    
    var buildings = [String]()
    var currentBuilding: String = ""
    var levels = [String:[String]]()
    var levelList = [String]()
    var currentLevel: String = ""
    
    var pastBuilding: String = ""
    var pastLevel: String = ""
    
    var isShow: Bool = false
    var isRadioMap: Bool = false
    var isOpen: Bool = false
    
    var coordToDisplay = CoordToDisplay()
    var resultToDisplay = ResultToDisplay()
    
    var isShowRP = false
    var countTap: Int = 0
    
    var headingImage = UIImage(named: "heading")
    var observerTime = 0
    
    let dropDown = DropDown()
    
    var modeAuto: Bool = false
    var isBleOnlyMode: Bool = false
    var isPathMatchingSuccess: Bool = true
    var isReportPpExist: Bool = false
    
    var resultPosBuffer = [[Double]]()
    var averagePosBuffer = [[Double]]()
    
    var isFileSaved: Bool = false
    // Neptune
    @IBOutlet weak var spotContentsView: UIView!
    
    var spotToDisplay = Spot()
    var spotAuthTime = 0
    var spotImage = UIImage(named: "spotPin")
    var spotCircle = UIImage(named: "spotCircle")
    
    let CCS_THRESHOLD: Double = 0.3
    
    // View
    var defaultHeight: CGFloat = 100
    
    private var foregroundObserver: Any!
    private var backgroundObserver: Any!
    private var terminateObserver: Any!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        setCardData(cardData: cardData!)
        
        setCells()
        setLevelCollectionView()
        
        initDropDown()
        setDropDown()
        
        switchButton.delegate = self
        switchButton.setSwitchButtonColor(colorName: self.cardData!.cardColor)
        self.imageLevel.bringSubviewToFront(switchButton)
        
        if (cardData?.sector_id != 0 && cardData?.sector_id != 7) {
            let firstBuilding: String = (cardData?.infoBuilding[0])!
            let firstBuildingLevels: [String] = (cardData?.infoLevel[firstBuilding])!
            
            displayLevelInfo(infoLevel: firstBuildingLevels)
            levelList = firstBuildingLevels
            isRadioMap = true
        } else {
            isRadioMap = false
        }
        
        fixChartHeight(flag: isRadioMap, region: self.region)
        
        headingImage = headingImage?.resize(newWidth: 20)
        self.spotContentsView.alpha = 0.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runMode = cardData!.mode
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        serviceManager.removeObserver(self)
        self.notificationCenterRemoveObserver()
        goToBack()
    }
    
    func goToBack() {
        self.forceStop()
        self.coordToDisplay = CoordToDisplay()
        self.resultToDisplay = ResultToDisplay()
        self.currentBuilding = ""
        self.currentLevel = ""
        self.pastBuilding = ""
        self.pastLevel = ""
        self.displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowRP)
        self.notificationCenterRemoveObserver()
        
        self.stopTimer()
        
        // serviceManager.stopService()
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func goToBackServiceFail() {
        self.forceStop()
        self.delegate?.sendPage(data: self.page)
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func forceStop() {
        serviceManager.forceStopService()
        serviceManager.removeObserver(self)
        self.notificationCenterRemoveObserver()
    }
    
    func setCardData(cardData: CardItemData) {
        self.sector_id = cardData.sector_id
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        if let topImage = UIImage(named: imageName) {
            self.cardTopImage.image = topImage
        } else {
            self.cardTopImage.image = UIImage(named: "purpleCardTop")
        }
        
        
        self.sectorNameLabel.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(self.showRP))
        self.sectorNameLabel.addGestureRecognizer(tapRecognizer)
        
        self.buildings = cardData.infoBuilding
        self.levels = removeValuesWith_D(in: cardData.infoLevel)
        
        self.currentBuilding = self.buildings[0]
        
        let numBuildings: Int = cardData.infoBuilding.count
        for building in 0..<numBuildings {
            let buildingName: String = cardData.infoBuilding[building]
            let levelNames: [String] = cardData.infoLevel[buildingName]!
            var levels = [String]()
            for i in 0..<levelNames.count {
                if (!levelNames[i].contains("_D")) {
                    levels.append(levelNames[i])
                }
            }
            let numLevels: Int = levels.count
            
            for level in 0..<numLevels {
                let levelName: String = levels[level]
                
                // Download RP
                let key: String = "\(buildingName)_\(levelName)"
                let rpXY = loadRP(fileName: key)
                if (!rpXY.isEmpty) {
                    RP[key] = rpXY
                }
                
                // Scale
                self.loadScale(sector_id: self.sector_id, building: buildingName, level: levelName)
            }
        }
    }
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
    }
    
    func movingAverage(data: [[Double]]) -> [Double] {
        var result: [Double] = data[0]
        
        var sumX: Double = 0
        var sumY: Double = 0
        for i in 0..<data.count {
            sumX += data[i][0]
            sumY += data[i][1]
        }
        
        let avgX = sumX/Double(data.count)
        let avgY = sumY/Double(data.count)
        result = [avgX, avgY]
        
        return result
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
    
    func fixChartHeight(flag: Bool, region: String) {
        if (flag) {
            let window = UIApplication.shared.keyWindow
            
            switch (region) {
            case "Korea":
                if ( cardData?.sector_id == 1 || cardData?.sector_id == 2 ) {
                    displayViewHeight.constant = 480
                } else {
                    let ratio: Double = 114900 / 68700
                    displayViewHeight.constant = displayView.bounds.width * ratio
                    let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                    defaultHeight = fusionView.bounds.height - 100 - displayViewHeight.constant - bottomPadding
                }
            case "Canada":
                if ( cardData?.sector_id == 4 ) {
                    displayViewHeight.constant = 480
                } else {
                    let ratio: Double = 114900 / 68700
                    displayViewHeight.constant = displayView.bounds.width * ratio
                    let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                    defaultHeight = fusionView.bounds.height - 100 - displayViewHeight.constant - bottomPadding
                }
            default:
                if ( cardData?.sector_id == 1 || cardData?.sector_id == 2 ) {
                    displayViewHeight.constant = 480
                } else {
                    let ratio: Double = 114900 / 68700
                    displayViewHeight.constant = displayView.bounds.width * ratio
                    let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                    defaultHeight = fusionView.bounds.height - 100 - displayViewHeight.constant - bottomPadding
                }
            }
        } else {
            displayViewHeight.constant = 480
        }
    }
    
    private func setCells() {
        LevelCollectionViewCell.register(target: levelCollectionView)
    }
    
    private func setLevelCollectionView() {
        levelCollectionView.delegate = self
        levelCollectionView.dataSource = self
        levelCollectionView.reloadData()
    }
    
    
    private func initDropDown() {
        dropView.layer.cornerRadius = 6
        //        dropView.borderColor = .blue1
        dropView.borderColor = .darkgrey4
        
        DropDown.appearance().textColor = UIColor.black // 아이템 텍스트 색상
        DropDown.appearance().selectedTextColor = UIColor.red // 선택된 아이템 텍스트 색상
        DropDown.appearance().backgroundColor = UIColor.white // 아이템 팝업 배경 색상
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGray // 선택한 아이템 배경 색상
        DropDown.appearance().setupCornerRadius(6)
        
        dropText.borderStyle = .none
        if (currentBuilding == "") {
            dropText.text = "Buildings"
        } else {
            dropText.text = self.currentBuilding
        }
        
        dropText.textColor = .darkgrey4
        
        dropDown.dismissMode = .automatic // 팝업을 닫을 모드 설정
    }
    
    private func setDropDown() {
        dropDown.dataSource = self.buildings
        dropDown.anchorView = self.dropView
        dropDown.bottomOffset = CGPoint(x: 0, y: dropView.bounds.height)
        dropDown.selectionAction = { [weak self] (index, item) in
            self!.dropText.text = item
            self!.currentBuilding = item
            self!.levelCollectionView.reloadData()
            self!.dropImage.image = UIImage.init(named: "showInfoToggle")
        }
        dropDown.cancelAction = { [weak self] in
            self!.dropImage.image = UIImage.init(named: "showInfoToggle")
        }
    }
    
    
    @IBAction func dropDownClicked(_ sender: UIButton) {
        dropDown.show()
        self.dropImage.image = UIImage.init(named: "closeInfoToggle")
    }
    
    func loadScale(sector_id: Int, building: String, level: String) {
        let key = "\(building)_\(level)"
        let input = Scale(sector_id: sector_id, building_name: building, level_name: level)
        Network.shared.postScale(url: SCALE_URL, input: input, completion: { [self] statusCode, returnedString, buildingLevel in
            let result = jsonToScale(json: returnedString)
            
            if (statusCode >= 200 && statusCode <= 300) {
                let scaleString = result.image_scale
                
                if (scaleString.isEmpty) {
                    chartLoad[buildingLevel] = true
                    chartLimits[key] = [0, 0, 0, 0]
                } else if (scaleString == "None") {
                    chartLoad[buildingLevel] = true
                    chartLimits[key] = [0, 0, 0, 0]
                } else {
                    let os = scaleString.components(separatedBy: "/")
                    let iosScale = os[1].components(separatedBy: " ")
                    
                    var data = [Double]()
                    if (iosScale.count < 4) {
                        chartLoad[buildingLevel] = true
                        chartLimits[key] = [0, 0, 0, 0]
                    } else {
                        for i in 0..<iosScale.count {
                            data.append(Double(iosScale[i])!)
                        }
                        chartLoad[buildingLevel] = true
                        chartLimits[key] = data
                    }
                }
            } else {
                chartLoad[buildingLevel] = false
            }
        })
    }
    
    private func loadRP(fileName: String) -> [[Double]] {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            return [[Double]]()
        }
        let rpXY:[[Double]] = parseRP(url: URL(fileURLWithPath: path))
        
        return rpXY
    }
    
    private func parseRP(url:URL) -> [[Double]] {
        var rpXY = [[Double]]()
        print(url)
        var rpX = [Double]()
        var rpY = [Double]()
        
        do {
            let data = try Data(contentsOf: url)
            let dataEncoded = String(data: data, encoding: .utf8)
            
            if let dataArr = dataEncoded?.components(separatedBy: "\n").map({$0.components(separatedBy: ",")}) {
                for item in dataArr {
                    let rp: [String] = item
                    if (rp.count >= 2) {
                        if (self.runMode == "pdr") {
                            guard let x: Double = Double(rp[1]) else { return [[Double]]() }
                            guard let y: Double = Double(rp[2].components(separatedBy: "\r")[0]) else { return [[Double]]() }
                            
                            rpX.append(x)
                            rpY.append(y)
                        } else {
                            let pathType = Int(rp[0])
                            if (pathType == 1) {
                                guard let x: Double = Double(rp[1]) else { return [[Double]]() }
                                guard let y: Double = Double(rp[2].components(separatedBy: "\r")[0]) else { return [[Double]]() }
                                
                                rpX.append(x)
                                rpY.append(y)
                            }
                        }
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
        if (timer == nil) {
            self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer!, forMode: .common)
        }
        
        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".pathPixelTimer")
        pathPixelTimer = DispatchSource.makeTimerSource(queue: queue)
        pathPixelTimer!.schedule(deadline: .now(), repeating: PP_CHECK_INTERVAL)
        pathPixelTimer!.setEventHandler(handler: self.pathPixelTimerUpdate)
        pathPixelTimer!.activate()
    }
    
    func stopTimer() {
        if (timer != nil) {
            self.timer!.invalidate()
            self.timer = nil
        }
        
        pathPixelTimer?.cancel()
        self.isReportPpExist = false
    }
    
    @objc func timerUpdate() {
        let timeStamp: Double = getCurrentTimeInMillisecondsDouble()
        
        // Map
        self.updateCoord(data: self.coordToDisplay, flag: self.isShowRP)
        if (spotAuthTime != 0) {
            if (Int(timeStamp) - self.spotAuthTime > 3000) {
                let spotXY: [Double] = [Double(self.spotToDisplay.spot_x), Double(self.spotToDisplay.spot_y)]
                dissapearSpot(XY: spotXY)
                self.spotAuthTime = 0
            }
        }
        
        // Info
        if (serviceManager.displayOutput.isIndexChanged) {
            resultToDisplay.level = serviceManager.displayOutput.level
            
            displayLevelInfo(infoLevel: levels[currentBuilding] ?? [])
            resultToDisplay.numLevels = self.numLevels
            resultToDisplay.infoLevels = self.infoOfLevels
            resultToDisplay.velocity = serviceManager.displayOutput.velocity
            resultToDisplay.heading = serviceManager.displayOutput.heading
            
            resultToDisplay.unitIndexTx = serviceManager.displayOutput.indexTx
            resultToDisplay.unitIndexRx = serviceManager.displayOutput.indexRx
            resultToDisplay.unitLength = serviceManager.displayOutput.length
            resultToDisplay.scc = serviceManager.displayOutput.scc
            resultToDisplay.phase = serviceManager.displayOutput.phase
        }
    }
    
    @objc func pathPixelTimerUpdate() {
        if (!self.isReportPpExist) {
            let builidng: String = self.coordToDisplay.building
            let level: String = self.coordToDisplay.level
            let key: String = "\(builidng)_\(level)"
            
            DispatchQueue.main.async {
                if (builidng != "" && level != "") {
                    if let isLoadEnd = self.serviceManager.isLoadEnd[key] {
                        if (isLoadEnd[0] && !isLoadEnd[1]) {
                            self.isReportPpExist = true
                            
                            self.serviceManager.stopService()
                            self.noImageLabel.text = "Cannot load the Path-Pixel"
                            self.noImageLabel.isHidden = false
                            self.imageLevel.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    private func makeUniqueId(uuid: String) -> String {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        let unique_id: String = "\(uuid)_\(currentTime)"
        
        return unique_id
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
    
    private func loadLevel(building: String, level: String, flag: Bool, completion: @escaping (UIImage?, Error?) -> Void) {
        let urlString: String = "https://storage.googleapis.com/\(IMAGE_URL)/map/\(self.sector_id)/\(building)_\(level).png"
        if let urlLevel = URL(string: urlString) {
            let cacheKey = NSString(string: urlString)
            
            if let cachedImage = ImageCacheManager.shared.object(forKey: cacheKey) {
                completion(cachedImage, nil)
            } else {
                let task = URLSession.shared.dataTask(with: urlLevel) { (data, response, error) in
                    if let error = error {
                        completion(nil, error)
                    }
                    
                    if let data = data, let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200 {
                        DispatchQueue.main.async {
                            ImageCacheManager.shared.setObject(UIImage(data: data)!, forKey: cacheKey)
                            completion(UIImage(data: data), nil)
                        }
                    } else {
                        completion(nil, error)
                    }
                }
                task.resume()
            }
        } else {
            completion(nil, nil)
        }
    }
    
    private func displayLevelImage(building: String, level: String, flag: Bool) {
        self.loadLevel(building: building, level: level, flag: flag, completion: { [self] data, error in
            DispatchQueue.main.async {
                if (data != nil) {
                    // 빌딩 -> 층 이미지가 있는 경우
                    self.imageLevel.isHidden = false
                    self.noImageLabel.isHidden = true
                    self.imageLevel.image = data
                } else {
                    // 빌딩 -> 층 이미지가 없는 경우
                    if (flag) {
                        self.imageLevel.isHidden = false
                        self.noImageLabel.isHidden = true

                        self.imageLevel.image = UIImage(named: "emptyLevel")
                    } else {
                        self.scatterChart.isHidden = true
                        switch (self.region) {
                        case "Korea":
                            self.noImageLabel.text = "There is no image of floor"
                        case "Canada":
                            self.noImageLabel.text = "There is no image of floor"
                        default:
                            self.noImageLabel.text = "There is no image of floor"
                        }
                        self.noImageLabel.isHidden = false
                        self.imageLevel.isHidden = true
                    }
                }
            }
        })
    }
    
    private func drawUser(XY: [Double], heading: Double, limits: [Double], isBleOnlyMode: Bool, isPmSuccess: Bool, isIndoor: Bool) {
        let values1 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        var valueColor = UIColor.systemRed
        if (!isIndoor) {
            valueColor = .systemGray
        } else if (isBleOnlyMode) {
            valueColor = UIColor.systemBlue
        } else if (!isPmSuccess) {
            valueColor = .systemOrange
        } else {
            valueColor = UIColor.systemRed
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "USER")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.circle)

        set1.setColor(valueColor)
        set1.scatterShapeSize = 16
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.setDrawValues(false)
        
        // Heading
        let point = scatterChart.getPosition(entry: ChartDataEntry(x: XY[0], y: XY[1]), axis: .left)
        let imageView = UIImageView(image: headingImage!.rotate(degrees: -heading+90))
        imageView.frame = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
        imageView.contentMode = .center
        imageView.tag = 100
        if let viewWithTag = scatterChart.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
        scatterChart.addSubview(imageView)
        
        let chartFlag: Bool = false
        scatterChart.isHidden = false
//        print("\(currentBuilding) \(currentLevel) Limits : \(limits[0]) , \(limits[1]), \(limits[2]), \(limits[3])")
        
        // Configure Chart
        scatterChart.xAxis.axisMinimum = limits[0]
        scatterChart.xAxis.axisMaximum = limits[1]
        scatterChart.leftAxis.axisMinimum = limits[2]
        scatterChart.leftAxis.axisMaximum = limits[3]
        
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
    
    private func drawDebug(XY: [Double], RP_X: [Double], RP_Y: [Double],  serverXY: [Double], tuXY: [Double], heading: Double, limits: [Double], isBleOnlyMode: Bool, isPmSuccess: Bool, trajectoryStartCoord: [Double], userTrajectory: [[Double]], searchArea: [[Double]], searchType: Int, isIndoor: Bool) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y
        
        let values0 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
        }
        
        var valueColor = UIColor.systemRed
        if (!isIndoor) {
            valueColor = UIColor.systemGray
        } else if (isBleOnlyMode) {
            valueColor = UIColor.systemBlue
        } else if (!isPmSuccess) {
            valueColor = .systemOrange
        } else {
            valueColor = UIColor.systemRed
        }
        
        let set0 = ScatterChartDataSet(entries: values0, label: "RP")
        set0.drawValuesEnabled = false
        set0.setScatterShape(.square)
        set0.setColor(UIColor.yellow)
        set0.scatterShapeSize = 3
        
        let values1 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        let set1 = ScatterChartDataSet(entries: values1, label: "USER")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.circle)
        set1.setColor(valueColor)
        set1.scatterShapeSize = 16
        
        let values2 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: serverXY[0], y: serverXY[1])
        }
        
        let set2 = ScatterChartDataSet(entries: values2, label: "SERVER")
        set2.drawValuesEnabled = false
        set2.setScatterShape(.circle)
        set2.setColor(.yellow)
        set2.scatterShapeSize = 12
        
        let values3 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: tuXY[0], y: tuXY[1])
        }
        
        let set3 = ScatterChartDataSet(entries: values3, label: "TU")
        set3.drawValuesEnabled = false
        set3.setScatterShape(.circle)
        set3.setColor(.systemGreen)
        set3.scatterShapeSize = 12
        
        let chartData = ScatterChartData(dataSet: set0)
        chartData.append(set1)
        chartData.append(set2)
        chartData.append(set3)
        chartData.setDrawValues(false)
        
        // Heading
        let point = scatterChart.getPosition(entry: ChartDataEntry(x: XY[0], y: XY[1]), axis: .left)
        let imageView = UIImageView(image: headingImage!.rotate(degrees: -heading+90))
        imageView.frame = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
        imageView.contentMode = .center
        imageView.tag = 100
        if let viewWithTag = scatterChart.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
        scatterChart.addSubview(imageView)
        
        let point2 = scatterChart.getPosition(entry: ChartDataEntry(x: serverXY[0], y: serverXY[1]), axis: .left)
        let imageView2 = UIImageView(image: headingImage!.rotate(degrees: -serverXY[2]+90))
        imageView2.frame = CGRect(x: point2.x - 15, y: point2.y - 15, width: 30, height: 30)
        imageView2.contentMode = .center
        imageView2.tag = 200
        if let viewWithTag2 = scatterChart.viewWithTag(200) {
            viewWithTag2.removeFromSuperview()
        }
        scatterChart.addSubview(imageView2)
        
        let point3 = scatterChart.getPosition(entry: ChartDataEntry(x: tuXY[0], y: tuXY[1]), axis: .left)
        let imageView3 = UIImageView(image: headingImage!.rotate(degrees: -tuXY[2]+90))
        imageView3.frame = CGRect(x: point3.x - 15, y: point3.y - 15, width: 30, height: 30)
        imageView3.contentMode = .center
        imageView3.tag = 300
        if let viewWithTag3 = scatterChart.viewWithTag(300) {
            viewWithTag3.removeFromSuperview()
        }
        scatterChart.addSubview(imageView3)
        
        let chartFlag: Bool = false
        scatterChart.isHidden = false
        
        let xMin = xAxisValue.min()!
        let xMax = xAxisValue.max()!
        let yMin = yAxisValue.min()!
        let yMax = yAxisValue.max()!
        
        print("\(currentBuilding) \(currentLevel) MinMax : \(xMin) , \(xMax), \(yMin), \(yMax)")
        print("\(currentBuilding) \(currentLevel) Limits : \(limits[0]) , \(limits[1]), \(limits[2]), \(limits[3])")
        
//        scatterChart.xAxis.axisMinimum = 2.2
//        scatterChart.xAxis.axisMaximum = 100.6
//        scatterChart.leftAxis.axisMinimum = -1
//        scatterChart.leftAxis.axisMaximum = 111.2
        
//        scatterChart.xAxis.axisMinimum = 2.0
//        scatterChart.xAxis.axisMaximum = 100.6
//        scatterChart.leftAxis.axisMinimum = 0.1
//        scatterChart.leftAxis.axisMaximum = 110.4
        
//        scatterChart.xAxis.axisMinimum = -1.0
//        scatterChart.xAxis.axisMaximum = 77.4
//        scatterChart.leftAxis.axisMinimum = -19.4
//        scatterChart.leftAxis.axisMaximum = 70.2
        
        if ( limits[0] == 0 && limits[1] == 0 && limits[2] == 0 && limits[3] == 0 ) {
            scatterChart.xAxis.axisMinimum = xMin - 5
            scatterChart.xAxis.axisMaximum = xMax + 5
            scatterChart.leftAxis.axisMinimum = yMin - 5
            scatterChart.leftAxis.axisMaximum = yMax + 5
        } else {
            scatterChart.xAxis.axisMinimum = limits[0]
            scatterChart.xAxis.axisMaximum = limits[1]
            scatterChart.leftAxis.axisMinimum = limits[2]
            scatterChart.leftAxis.axisMaximum = limits[3]
        }
        
        
        // Configure Chart
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
    
    func updateCoord(data: CoordToDisplay, flag: Bool) {
        self.XY[0] = data.x
        self.XY[1] = data.y
        let isIndoor: Bool = data.isIndoor
        
        if (data.building == "") {
            currentBuilding = buildings[0]
        } else {
            currentBuilding = data.building
            if (data.level == "") {
                currentLevel = levels[currentBuilding]![0]
            } else {
                currentLevel = data.level
            }
        }
        
        if (pastBuilding != currentBuilding || pastLevel != currentLevel) {
            displayLevelImage(building: currentBuilding, level: currentLevel, flag: flag)
        }
        
        pastBuilding = currentBuilding
        pastLevel = currentLevel
        
        
        let key = "\(currentBuilding)_\(currentLevel)"
        let condition: ((String, [[Double]])) -> Bool = {
            $0.0.contains(key)
        }
        let rp: [[Double]] = RP[key] ?? [[Double]]()
        var limits: [Double] = chartLimits[key] ?? [0, 0, 0, 0]
        
        let heading: Double = data.heading
        
        if (flag) {
            if (RP.contains(where: condition)) {
                if (rp.isEmpty) {
                    scatterChart.isHidden = true
                } else {
                    drawDebug(XY: XY, RP_X: rp[0], RP_Y: rp[1], serverXY: serviceManager.serverResult, tuXY: serviceManager.timeUpdateResult, heading: heading, limits: limits, isBleOnlyMode: self.isBleOnlyMode, isPmSuccess: self.isPathMatchingSuccess, trajectoryStartCoord: serviceManager.displayOutput.trajectoryStartCoord, userTrajectory: serviceManager.displayOutput.userTrajectory, searchArea: serviceManager.displayOutput.searchArea, searchType: serviceManager.displayOutput.searchType, isIndoor: isIndoor)
                }
            }
        } else {
            if (buildings.contains(currentBuilding)) {
                if (XY[0] != 0 && XY[1] != 0) {
                    drawUser(XY: XY, heading: heading, limits: limits, isBleOnlyMode: self.isBleOnlyMode, isPmSuccess: self.isPathMatchingSuccess, isIndoor: isIndoor)
                }
            }
        }
        dropText.text = currentBuilding
    }
    

    func hideDropDown(flag: Bool) {
        if (flag) {
            // Hide
            UIView.animate(withDuration: 0.5, animations: {self.dropView.alpha = 0.0}, completion: { isFinished in if isFinished {
                self.dropView.isHidden = true
            }})
            
            UIView.animate(withDuration: 0.5, animations: {self.levelCollectionView.alpha = 0.0}, completion: { isFinished in if isFinished {
                self.levelCollectionView.isHidden = true
            }})
            
            switchButtonOffset.constant = -30
        } else {
            // Show
            UIView.animate(withDuration: 0.5, animations: {self.dropView.alpha = 1.0}, completion: { isFinished in if isFinished {
                self.dropView.isHidden = false
            }})
            
            UIView.animate(withDuration: 0.5, animations: {self.levelCollectionView.alpha = 1.0}, completion: { isFinished in if isFinished {
                self.levelCollectionView.isHidden = false
            }})
            
            switchButtonOffset.constant = 10
        }
    }
    
    @IBAction func tapOnSpotButton(_ sender: UIButton) {
        serviceManager.getSpotResult(completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result: OnSpotAuthorizationResult = decodeOSA(json: returnedString)
                if (result.spots.count > 0) {
                    // Find Highest Prob
                    var bestIndex: Int = 0
                    var bestProb: Double = 0
                    for i in 0..<result.spots.count {
                        let data = result.spots[i]
                        let prob = data.ccs
                        if (prob > bestProb) {
                            bestProb = prob
                            bestIndex = i
                        }
                    }
                    
                    let data = result.spots[bestIndex]
                    
                    if (data.ccs >= CCS_THRESHOLD) {
                        showOSAResult(data: data, flag: isShowRP)
                    } else {
                        print("(Jupiter) Fail : No Matched Spot")
                        self.scatterChart.isHidden = true
                        self.spotToDisplay.building_name = "Invalid"
                        self.spotToDisplay.spot_name = "Invalid"
                        self.spotToDisplay.spot_feature_id = 0
                        self.spotToDisplay.ccs = data.ccs
                    }
                }
            } else {
                print("(Jupiter) Warnings : \(statusCode) , Cannot find spot")
            }
        })
    }
    
    
    func showOSAResult(data: Spot, flag: Bool) {
        self.spotAuthTime = data.mobile_time
        
        let spotX = Double(data.spot_x) // -9.5
        let spotY = Double(data.spot_y) // -14
        let XY: [Double] = [spotX, spotY]
        
        self.spotToDisplay = data
        
        let key = "\(currentBuilding)_\(currentLevel)"
        let condition: ((String, [[Double]])) -> Bool = {
            $0.0.contains(key)
        }
        
        let limits: [Double] = chartLimits[key] ?? [0, 0, 0, 0]
        let rp: [[Double]] = RP[key] ?? [[Double]]()
        
        if (flag) {
            if (RP.contains(where: condition)) {
                if (rp.isEmpty) {
                    scatterChart.isHidden = true
                } else {
                    showSpotContents(data: data)
                    drawSpot(XY: XY, limits: limits)
                }
            }
        } else {
            showSpotContents(data: data)
            drawSpot(XY: XY, limits: limits)
        }
    }
    
    private func drawSpot(XY: [Double], limits: [Double]) {
        scatterChart.isHidden = false
        
        let chartFlag: Bool = false
        scatterChart.xAxis.axisMinimum = limits[0]
        scatterChart.xAxis.axisMaximum = limits[1]
        scatterChart.leftAxis.axisMinimum = limits[2]
        scatterChart.leftAxis.axisMaximum = limits[3]
        
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
        
        let values1 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let set1 = ScatterChartDataSet(entries: values1, label: "USER")
        set1.drawValuesEnabled = false
        set1.setScatterShape(.circle)

        set1.setColor(UIColor.clear)
        set1.scatterShapeSize = 1
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.setDrawValues(false)
        
        scatterChart.data = chartData
        
        let point = scatterChart.getPosition(entry: ChartDataEntry(x: XY[0], y: XY[1]), axis: .left)
        
        // Spot Image Size (default = 120)
        let imageCircle = UIImageView(image: spotCircle?.resize(newWidth: 60))
        imageCircle.alpha = 0.6
        imageCircle.frame = CGRect(x: point.x-15, y: point.y-35, width: 30, height: 30)
        imageCircle.contentMode = .center
        imageCircle.tag = 150
        
        let imageView = UIImageView(image: spotImage?.resize(newWidth: 20))
        imageView.frame = CGRect(x: point.x-15, y: point.y-35, width: 30, height: 30)
        imageView.contentMode = .center
        imageView.tag = 151
        
        if let viewWithTagCircle = scatterChart.viewWithTag(150) {
            viewWithTagCircle.removeFromSuperview()
        }
        
        if let viewWithTagPin = scatterChart.viewWithTag(151) {
            viewWithTagPin.removeFromSuperview()
        }
        
        
        UIView.animate(withDuration: 0.5) {
            self.scatterChart.addSubview(imageView)
            self.scatterChart.addSubview(imageCircle)
        }
        
    }
    
    private func dissapearSpot(XY: [Double]) {
        if let viewWithTagCircle = scatterChart.viewWithTag(150) {
            UIView.animate(withDuration: 1.0) {
                viewWithTagCircle.removeFromSuperview()
            }
        }
        
        if let viewWithTagPin = scatterChart.viewWithTag(151) {
            UIView.animate(withDuration: 1.0) {
                viewWithTagPin.removeFromSuperview()
            }
        }
        self.spotContentsView.alpha = 0.0
        self.mainImage.image = UIImage(named: "TJLABS_Total")
    }
    
    func showSpotContents(data: Spot) {
        let sector = data.sector_name
        let building = data.building_name
        let level = data.level_name
        let spotId = data.spot_id
        let spotNumber = data.spot_number
        let spotName = data.spot_name
        let spotX: Double = Double(data.spot_x)
        let spotY: Double = Double(data.spot_y)
        let sfId = data.spot_feature_id
        let ccs = data.ccs
        
        UIView.animate(withDuration: 0.5) {
            self.spotContentsView.alpha = 1.0
        }
        
        let locationName: String = building + " in " + sector
        let sfImageName: String = "sf_id_\(sfId)_small"
        self.mainImage.image = UIImage(named: sfImageName)
        
        self.spotBuildingLabel.text = locationName
        self.spotLevelLabel.text = level
        self.spotNameLabel.text = spotName
        self.spotCcsLabel.text = String(format: "%.4f", ccs)
    }
    
    func notificationCenterAddObserver() {
        self.backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            self.serviceManager.setBackgroundMode(flag: true)
        }
        
        self.foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            self.serviceManager.setBackgroundMode(flag: false)
        }
        
        self.terminateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            self.forceStop()
        }
    }
    
    func notificationCenterRemoveObserver() {
        NotificationCenter.default.removeObserver(self.backgroundObserver)
        NotificationCenter.default.removeObserver(self.foregroundObserver)
        NotificationCenter.default.removeObserver(self.terminateObserver)
    }
}


extension FusionViewController : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentLevel = levels[currentBuilding]![indexPath.row]
        
        displayLevelInfo(infoLevel: levels[currentBuilding]!)
        resultToDisplay.numLevels = self.numLevels
        resultToDisplay.infoLevels = self.infoOfLevels
        
        let key = "\(currentBuilding)_\(currentLevel)"
        let rp: [[Double]] = RP[key] ?? [[Double]]()
        
        var limits: [Double] = chartLimits[key] ?? [0, 0, 0, 0]
        
        if (rp.isEmpty) {
            // RP가 없어서 그리지 않음
            scatterChart.isHidden = true
        } else {
            if (isShowRP) {
                drawDebug(XY: XY, RP_X: rp[0], RP_Y: rp[1], serverXY: serviceManager.serverResult, tuXY: serviceManager.timeUpdateResult, heading: 0, limits: limits, isBleOnlyMode: self.isBleOnlyMode, isPmSuccess: self.isPathMatchingSuccess, trajectoryStartCoord: serviceManager.displayOutput.trajectoryStartCoord, userTrajectory: serviceManager.displayOutput.userTrajectory, searchArea: serviceManager.displayOutput.searchArea, searchType: serviceManager.displayOutput.searchType, isIndoor: false)
            }
            displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowRP)
        }
        
        levelCollectionView.reloadData()
    }
    
}

extension FusionViewController : UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        levels[currentBuilding]!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let levelCollectionView = collectionView.dequeueReusableCell(withReuseIdentifier: LevelCollectionViewCell.className, for: indexPath)
                as? LevelCollectionViewCell else {return UICollectionViewCell()}

        levelCollectionView.setName(level: levels[currentBuilding]![indexPath.row],
                                    isClicked: currentLevel == levels[currentBuilding]![indexPath.row] ? true : false)
        displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowRP)
        
        levelCollectionView.layer.cornerRadius = 15
        levelCollectionView.layer.borderColor = UIColor.darkgrey4.cgColor
        levelCollectionView.layer.borderWidth = 1
        
        return levelCollectionView
    }
}

extension FusionViewController : UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.text = levels[currentBuilding]![indexPath.row]
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
        return UIEdgeInsets(top: 0.01, left: 20, bottom: 0, right: 20)
    }
}

extension FusionViewController: CustomSwitchButtonDelegate {
    func isOnValueChange(isOn: Bool) {
        DispatchQueue.main.async { [self] in
            self.modeAuto = isOn
            if (isOn) {
                self.hideDropDown(flag: true)
                serviceManager = ServiceManager()
                serviceManager.changeRegion(regionName: self.region)
                serviceManager.setSimulationMode(flag: false, bleFileName: "ble_lg_eval06.csv", sensorFileName: "sensor_lg_eval06.csv")
                
                var inputMode: String = "auto"
                if (self.sector_id == 6 && self.region != "Canada") {
                    inputMode = "auto"
                } else {
                    inputMode = cardData!.mode
                }
                let uniqueId = self.makeUniqueId(uuid: uuid)
                serviceManager.startService(id: uniqueId, sector_id: cardData!.sector_id, service: serviceName, mode: cardData!.mode, completion: { isStart, message in
                    if (isStart) {
                        serviceManager.addObserver(self)
                        print("(FusionVC) Success : \(message)")
                        self.notificationCenterAddObserver()
                        self.startTimer()
                    } else {
                        print("(FusionVC) Fail : \(message)")
                        serviceManager.stopService()
                        self.goToBackServiceFail()
                    }
                })
            } else {
                self.hideDropDown(flag: false)
                let isStop = serviceManager.stopService()
                if (isStop.0) {
                    self.isFileSaved = self.serviceManager.saveSimulationFile()
                    
                    self.coordToDisplay = CoordToDisplay()
                    self.resultToDisplay = ResultToDisplay()
                    
                    self.currentBuilding = ""
                    self.currentLevel = ""
                    self.pastBuilding = ""
                    self.pastLevel = ""
                    self.displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowRP)
                    self.notificationCenterRemoveObserver()
                    print("(FusionVC) Success : \(isStop.1)")
                    serviceManager.removeObserver(self)
                    self.stopTimer()
                    
                    if (self.isFileSaved) {
                        goToBack()
                    }
                } else {
                    print("(FusionVC) Fail : \(isStop.1)")
                    let message: String = isStop.1
//                    showPopUp(title: "Service Fail", message: message)
                    self.goToBackServiceFail()
                }
            }
        }
    }
}
