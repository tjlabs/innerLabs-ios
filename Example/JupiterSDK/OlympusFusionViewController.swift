import UIKit
import OlympusSDK
import Alamofire
import Kingfisher
import ExpyTableView
import Charts
import DropDown

class OlympusFusionViewController: UIViewController, Observer {
    
    func report(flag: Int) {
        let localTime = getLocalTimeString()
        switch(flag) {
        case 0:
            print(localTime + " , (ServiceVC) Report : Stop!! Out of the Service Area")
        case 1:
            print(localTime + " , (ServiceVC) Report : Start!! Enter the Service Area")
        case 2:
            print(localTime + " , (ServiceVC) Report : BLE is Off")
        case -1:
            print(localTime + " , (ServiceVC) Report : Abnormal!! Restart the Service")
        case 3:
            print(localTime + " , (ServiceVC) Report : Start!! Run Venus Mode")
        case 4:
            print(localTime + " , (ServiceVC) Report : Start!! Run Jupiter Mode")
        case 5:
            print(localTime + " , (ServiceVC) Report : Waiting Server Result...")
        case 6:
            print(localTime + " , (ServiceVC) Report : Network Connection Lost")
        case 7:
            print(localTime + " , (ServiceVC) Report : Enter Backgroud")
        case 8:
            print(localTime + " , (ServiceVC) Report : Enter Foreground")
        case 9:
            print(localTime + " , (ServiceVC) Report : Fail to encode RFD")
        case 10:
            print(localTime + " , (ServiceVC) Report : Fail to encode UVD")
        case 11:
            print(localTime + " , (ServiceVC) Report : Fail to scan RFD")
        case 12:
            print(localTime + " , (ServiceVC) Report : Fail to create RFD")
        default:
            print(localTime + " , (ServiceVC) Default Flag")
        }
    }
    
    func update(result: FineLocationTrackingResult) {
        DispatchQueue.main.async {
            let localTime: String = getLocalTimeString()
            let dt = result.mobile_time - self.observerTime
            let log: String = localTime + " , (ServiceVC) : isIndoor = \(result.isIndoor) // dt = \(dt) // mode = \(result.mode) // x = \(result.x) // y = \(result.y) // index = \(result.index) // phase = \(result.phase)"
            
            self.observerTime = result.mobile_time
            let building = result.building_name
            let level = result.level_name
            var x = result.x
            var y = result.y

            if (result.ble_only_position) {
                self.isBleOnlyMode = true
            } else {
                self.isBleOnlyMode = false
            }
            self.isPathMatchingSuccess = self.serviceManager.displayOutput.isPmSuccess
            
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
        }
    }
    
    
    @IBOutlet var FusionView: UIView!
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
    
    var serviceManager = OlympusServiceManager()
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
    
    var isRadioMap: Bool = false
    
    var coordToDisplay = CoordToDisplay()
    var resultToDisplay = ResultToDisplay()
    
    var isShowPathPixel = false
    var countTap: Int = 0
    
    var headingImage = UIImage(named: "heading")
    var observerTime = 0
    
    let dropDown = DropDown()
    
    var modeAuto: Bool = false
    var isBleOnlyMode: Bool = false
    var isPathMatchingSuccess: Bool = true
    
    var PpLoaded = [String: Bool]()
    var PpType = [String: [Int]]()
    var PpNode = [String: [Int]]()
    var PpCoord = [String: [[Double]]]()
    var PpMinMax = [Double]()
    var PpMagScale = [String: [Double]]()
    var PpHeading = [String: [String]]()
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
        self.displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowPathPixel)
        self.notificationCenterRemoveObserver()
        
        self.stopTimer()
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
        if (!self.isFileSaved) {
            serviceManager.saveSimulationFile()
        }
        serviceManager.stopService()
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
        tapRecognizer.addTarget(self, action: #selector(self.showPathPixel))
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
                loadPathPixelFile(building: buildingName, level: levelName)
                self.loadScale(sector_id: self.sector_id, building: buildingName, level: levelName)
            }
        }
    }
    
    private func loadPathPixelFile(building: String, level: String) -> URL? {
        let key = "\(building)_\(level)"
        
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print(getLocalTimeString() + " , (ServiceVC) FileManager : Unable to access document directory.")
            PpLoaded[key] = false
            return nil
        }
        
        let fileName: String = "\(building)_\(level).csv"
        let ppFileUrl = documentDirectoryUrl.appendingPathComponent(fileName)
        do {
            let contents = try String(contentsOf: ppFileUrl)
            ( PpType[key], PpNode[key], PpCoord[key], PpMagScale[key], PpHeading[key] ) = parsePathPixel(data: contents)
            PpLoaded[key] = true
        } catch {
            print("Error reading file:", error.localizedDescription)
            PpLoaded[key] = false
            return nil
        }
        
        return ppFileUrl
    }
    
    private func parsePathPixel(data: String)  -> ([Int], [Int], [[Double]], [Double], [String]) {
        var roadType = [Int]()
        var roadNode = [Int]()
        var road = [[Double]]()
        var roadScale = [Double]()
        var roadHeading = [String]()
        
        var roadX = [Double]()
        var roadY = [Double]()
        
        let roadString = data.components(separatedBy: .newlines)
        for i in 0..<roadString.count {
            if (roadString[i] != "") {
                let lineString: String = roadString[i]
                let lineData = roadString[i].components(separatedBy: ",")
                
                guard let type = Int(lineData[0].trimmingCharacters(in: .whitespaces)),
                      let node = Int(lineData[1].trimmingCharacters(in: .whitespaces)),
                      let x = Double(lineData[2].trimmingCharacters(in: .whitespaces)),
                      let y = Double(lineData[3].trimmingCharacters(in: .whitespaces)),
                      let scale = Double(lineData[4].trimmingCharacters(in: .whitespaces)) else {
                    continue
                }
                
                roadType.append(type)
                roadNode.append(node)
                roadX.append(x)
                roadY.append(y)
                roadScale.append(scale)
                
                let headingString = extractContentBetweenBrackets(from: lineString).replacingOccurrences(of: " ", with: "")
                roadHeading.append(headingString)
            }
        }
        road = [roadX, roadY]
        self.PpMinMax = [roadX.min() ?? 0, roadY.min() ?? 0, roadX.max() ?? 0, roadY.max() ?? 0]
        
        return (roadType, roadNode, road, roadScale, roadHeading)
    }
    
    private func extractContentBetweenBrackets(from string: String) -> String {
        let pattern = "\\[([^\\]]+)\\]"
        var extractedContent = ""
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = string as NSString
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            
            for match in matches {
                let nsRange = match.range(at: 1)
                let matchString = nsString.substring(with: nsRange)
                extractedContent.append(matchString)
                extractedContent.append(" ")
            }
        } catch {
            print("Invalid regular expression pattern")
        }
        
        return extractedContent.trimmingCharacters(in: .whitespaces)
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
    
    @objc func showPathPixel() {
        countTap += 1
        
        if (countTap == 5) {
            isShowPathPixel = true
            self.sectorNameLabel.textColor = .yellow
            for view in self.scatterChart.subviews {
                view.removeFromSuperview()
            }
            
        } else if (countTap > 9) {
            isShowPathPixel = false
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
                    defaultHeight = FusionView.bounds.height - 100 - displayViewHeight.constant - bottomPadding
                }
            case "Canada":
                if ( cardData?.sector_id == 4 ) {
                    displayViewHeight.constant = 480
                } else {
                    let ratio: Double = 114900 / 68700
                    displayViewHeight.constant = displayView.bounds.width * ratio
                    let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                    defaultHeight = FusionView.bounds.height - 100 - displayViewHeight.constant - bottomPadding
                }
            default:
                if ( cardData?.sector_id == 1 || cardData?.sector_id == 2 ) {
                    displayViewHeight.constant = 480
                } else {
                    let ratio: Double = 114900 / 68700
                    displayViewHeight.constant = displayView.bounds.width * ratio
                    let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                    defaultHeight = FusionView.bounds.height - 100 - displayViewHeight.constant - bottomPadding
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
    
    
    @IBAction func dropDownClicked(_ sender: Any) {
        dropDown.show()
        self.dropImage.image = UIImage.init(named: "closeInfoToggle")
    }
    
    
    func loadScale(sector_id: Int, building: String, level: String) {
        let key = "\(building)_\(level)"
        let input = ScaleOlympus(sector_id: sector_id, building_name: building, level_name: level, operating_system: OPERATING_SYSTEM)
        Network.shared.postScaleOlympus(url: USER_SCALE_URL, input: input, completion: { [self] statusCode, returnedString, buildingLevel in
            let result = decodeScale(json: returnedString)
            if (statusCode >= 200 && statusCode <= 300) {
                var data = [Double]()
                let resultScale = result.image_scale
                if (resultScale.count < 4) {
                    chartLoad[buildingLevel] = true
                    chartLimits[key] = [0, 0, 0, 0]
                } else {
                    for i in 0..<resultScale.count {
                        data.append(resultScale[i])
                    }
                    chartLoad[buildingLevel] = true
                    chartLimits[key] = data
                }
            } else {
                chartLoad[buildingLevel] = false
            }
        })
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
    }
    
    @objc func timerUpdate() {
        let timeStamp: Double = getCurrentTimeInMillisecondsDouble()
        
        // Map
        self.updateCoord(data: self.coordToDisplay, flag: self.isShowPathPixel)
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
        let building: String = self.coordToDisplay.building
        let level: String = self.coordToDisplay.level
        let key: String = "\(building)_\(level)"
        
        DispatchQueue.main.async {
            if (building != "" && level != "") {
                if let isLoaded = self.PpLoaded[key] {
                    if (isLoaded) {
                        self.noImageLabel.isHidden = true
                        self.imageLevel.isHidden = false
                    } else {
                        if let ppUrl = self.loadPathPixelFile(building: building, level: level) {
                            self.noImageLabel.isHidden = true
                            self.imageLevel.isHidden = false
                        } else {
                            self.noImageLabel.text = "Cannot load the Path-Pixel"
                            self.noImageLabel.isHidden = false
                            self.imageLevel.isHidden = true
                        }
                    }
                } else {
                    self.noImageLabel.text = "Cannot load the Path-Pixel"
                    self.noImageLabel.isHidden = false
                    self.imageLevel.isHidden = true
                }
            }
        }
    }
    
    private func makeUniqueId(uuid: String) -> String {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        let unique_id: String = "\(uuid)_\(currentTime)"
        
        return unique_id
    }
    
    func decodeScale(json: String) -> ScaleResponseOlympus {
        let result = ScaleResponseOlympus(image_scale: [])
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(ScaleResponseOlympus.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    private func loadLevel(building: String, level: String, flag: Bool, completion: @escaping (UIImage?, Error?) -> Void) {
        let urlString: String = "\(USER_IMAGE_URL)/map/\(self.sector_id)/\(building)/\(level).png"
        print("IMAGE : URL = \(urlString)")
        if let urlLevel = URL(string: urlString) {
            let cacheKey = NSString(string: urlString)
            
            if let cachedImage = ImageCacheManager.shared.object(forKey: cacheKey) {
                print("IMAGE : cache")
                completion(cachedImage, nil)
            } else {
                let task = URLSession.shared.dataTask(with: urlLevel) { (data, response, error) in
                    if let error = error {
                        print("IMAGE : Error(1) = \(error)")
                        completion(nil, error)
                    }
                    
                    if let data = data, let httpResponse = response as? HTTPURLResponse,
                       httpResponse.statusCode == 200 {
                        DispatchQueue.main.async {
                            ImageCacheManager.shared.setObject(UIImage(data: data)!, forKey: cacheKey)
                            completion(UIImage(data: data), nil)
                        }
                    } else {
                        print("IMAGE : Error(2) = \(error)")
                        completion(nil, error)
                    }
                }
                task.resume()
            }
        } else {
            print("IMAGE : Error(3) = \(urlString)")
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
    
    private func drawResult(XY: [Double], heading: Double, limits: [Double], isBleOnlyMode: Bool, isPmSuccess: Bool, isIndoor: Bool) {
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
        
        if let viewWithTag2 = scatterChart.viewWithTag(200) {
            viewWithTag2.removeFromSuperview()
        }
        
        if let viewWithTag3 = scatterChart.viewWithTag(300) {
            viewWithTag3.removeFromSuperview()
        }
        
        let chartFlag: Bool = false
        scatterChart.isHidden = false
        print("\(currentBuilding) \(currentLevel) Limits : \(limits[0]) , \(limits[1]), \(limits[2]), \(limits[3])")
        
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
    
    private func drawDebug(XY: [Double], RP_X: [Double], RP_Y: [Double],  serverXY: [Double], tuXY: [Double], heading: Double, limits: [Double], isBleOnlyMode: Bool, isPmSuccess: Bool, trajectoryStartCoord: [Double], userTrajectory: [[Double]], searchArea: [[Double]], searchType: Int, isIndoor: Bool, trajPm: [[Double]], trajOg: [[Double]]) {
        let xAxisValue: [Double] = RP_X
        let yAxisValue: [Double] = RP_Y
        
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

        let values0 = (0..<xAxisValue.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: xAxisValue[i], y: yAxisValue[i])
        }
        
        let set0 = ScatterChartDataSet(entries: values0, label: "RP")
        set0.drawValuesEnabled = false
        set0.setScatterShape(.square)
        set0.setColor(UIColor.yellow)
        set0.scatterShapeSize = 4
        
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
        
        let values4 = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: trajectoryStartCoord[0], y: trajectoryStartCoord[1])
        }
        
        let set4 = ScatterChartDataSet(entries: values4, label: "startCoord")
        set4.drawValuesEnabled = false
        set4.setScatterShape(.circle)
        set4.setColor(.blue)
        set4.scatterShapeSize = 8
        
        let values5 = (0..<userTrajectory.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: userTrajectory[i][0], y: userTrajectory[i][1])
        }
        let set5 = ScatterChartDataSet(entries: values5, label: "Trajectory")
        set5.drawValuesEnabled = false
        set5.setScatterShape(.circle)
        set5.setColor(.black)
        set5.scatterShapeSize = 6
        
        let values6 = (0..<searchArea.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: searchArea[i][0], y: searchArea[i][1])
        }
        let set6 = ScatterChartDataSet(entries: values6, label: "SearchArea")
        set6.drawValuesEnabled = false
        set6.setScatterShape(.circle)
        
        let values7 = (0..<trajPm.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: trajPm[i][0], y: trajPm[i][1])
        }
        let set7 = ScatterChartDataSet(entries: values7, label: "TrajectoryPm")
        set7.drawValuesEnabled = false
        set7.setScatterShape(.circle)
        set7.setColor(.systemRed)
        set7.scatterShapeSize = 6
        
        let values8 = (0..<trajOg.count).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: trajOg[i][0], y: trajOg[i][1])
        }
        let set8 = ScatterChartDataSet(entries: values8, label: "TrajectoryOg")
        set8.drawValuesEnabled = false
        set8.setScatterShape(.circle)
        set8.setColor(.systemBlue)
        set8.scatterShapeSize = 6
        
        switch (searchType) {
        case 0:
            // 곡선
            set6.setColor(.systemYellow)
        case 1:
            // All 직선
            set6.setColor(.systemGreen)
        case 2:
            // Head 직선
            set6.setColor(.systemBlue)
        case 3:
            // Tail 직선
            set6.setColor(.blue3)
        case 4:
            // PDR_IN_PHASE4_HAS_MAJOR_DIR & Phase == 2 Request
            set6.setColor(.systemOrange)
        case 5:
            // PDR Phase < 4
            set6.setColor(.systemGreen)
        case 6:
            // PDR_IN_PHASE4_NO_MAJOR_DIR
            set6.setColor(.systemBlue)
        case 7:
            // PDR Phase = 4 & Empty Closest Index
            set6.setColor(.blue3)
        case -1:
            // Phase 2 & No Request
            set6.setColor(.red)
        case -2:
            // KF 진입 전
            set6.setColor(.systemBrown)
        default:
            set6.setColor(.systemTeal)
        }
        set6.scatterShapeSize = 6
        
        let chartData = ScatterChartData(dataSet: set0)
        chartData.append(set1)
        chartData.append(set2)
        chartData.append(set3)
        chartData.append(set4)
        chartData.append(set5)
        chartData.append(set6)
        chartData.append(set7)
        chartData.append(set8)
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
        
//        print("\(currentBuilding) \(currentLevel) MinMax : \(xMin) , \(xMax), \(yMin), \(yMax)")
//        print("\(currentBuilding) \(currentLevel) Limits : \(limits[0]) , \(limits[1]), \(limits[2]), \(limits[3])")
        
//        scatterChart.xAxis.axisMinimum = -5.8
//        scatterChart.xAxis.axisMaximum = 56.8
//        scatterChart.leftAxis.axisMinimum = -2.8
//        scatterChart.leftAxis.axisMaximum = 66.6
        
//        scatterChart.xAxis.axisMinimum = -4
//        scatterChart.xAxis.axisMaximum = 36
//        scatterChart.leftAxis.axisMinimum = -4
//        scatterChart.leftAxis.axisMaximum = 78
        
//        scatterChart.xAxis.axisMinimum = -4
//        scatterChart.xAxis.axisMaximum = 36
//        scatterChart.leftAxis.axisMinimum = -4.65
//        scatterChart.leftAxis.axisMaximum = 79
        
        // Configure Chart
        if ( limits[0] == 0 && limits[1] == 0 && limits[2] == 0 && limits[3] == 0 ) {
            scatterChart.xAxis.axisMinimum = xMin - 10
            scatterChart.xAxis.axisMaximum = xMax + 10
            scatterChart.leftAxis.axisMinimum = yMin - 10
            scatterChart.leftAxis.axisMaximum = yMax + 10
        } else {
            scatterChart.xAxis.axisMinimum = limits[0]
            scatterChart.xAxis.axisMaximum = limits[1]
            scatterChart.leftAxis.axisMinimum = limits[2]
            scatterChart.leftAxis.axisMaximum = limits[3]
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
        let pathPixel: [[Double]] = PpCoord[key] ?? [[Double]]()
        var limits: [Double] = chartLimits[key] ?? [0, 0, 0, 0]
        
        let heading: Double = data.heading
        
        if (flag) {
            if (PpCoord.contains(where: condition)) {
                if (pathPixel.isEmpty) {
                    scatterChart.isHidden = true
                } else {
                    drawDebug(XY: XY, RP_X: pathPixel[0], RP_Y: pathPixel[1], serverXY: serviceManager.displayOutput.serverResult, tuXY: serviceManager.timeUpdateResult, heading: heading, limits: limits, isBleOnlyMode: self.isBleOnlyMode, isPmSuccess: self.isPathMatchingSuccess, trajectoryStartCoord: serviceManager.displayOutput.trajectoryStartCoord, userTrajectory: serviceManager.displayOutput.userTrajectory, searchArea: serviceManager.displayOutput.searchArea, searchType: serviceManager.displayOutput.searchType, isIndoor: isIndoor, trajPm: serviceManager.displayOutput.trajectoryPm, trajOg: serviceManager.displayOutput.trajectoryOg)
                }
            }
        } else {
            if (buildings.contains(currentBuilding)) {
                if (XY[0] != 0 && XY[1] != 0) {
                    drawResult(XY: XY, heading: heading, limits: limits, isBleOnlyMode: self.isBleOnlyMode, isPmSuccess: true, isIndoor: isIndoor)
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
        let pathPixel: [[Double]] = PpCoord[key] ?? [[Double]]()
        
        if (flag) {
            if (PpCoord.contains(where: condition)) {
                if (pathPixel.isEmpty) {
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


extension OlympusFusionViewController : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentLevel = levels[currentBuilding]![indexPath.row]
        
        displayLevelInfo(infoLevel: levels[currentBuilding]!)
        resultToDisplay.numLevels = self.numLevels
        resultToDisplay.infoLevels = self.infoOfLevels
        
        let key = "\(currentBuilding)_\(currentLevel)"
        let pathPixel: [[Double]] = PpCoord[key] ?? [[Double]]()
        
        var limits: [Double] = chartLimits[key] ?? [0, 0, 0, 0]
        
        if (pathPixel.isEmpty) {
            // RP가 없어서 그리지 않음
            scatterChart.isHidden = true
        } else {
            if (isShowPathPixel) {
                drawDebug(XY: XY, RP_X: pathPixel[0], RP_Y: pathPixel[1], serverXY: serviceManager.displayOutput.serverResult, tuXY: serviceManager.timeUpdateResult, heading: 0, limits: limits, isBleOnlyMode: self.isBleOnlyMode, isPmSuccess: self.isPathMatchingSuccess, trajectoryStartCoord: serviceManager.displayOutput.trajectoryStartCoord, userTrajectory: serviceManager.displayOutput.userTrajectory, searchArea: serviceManager.displayOutput.searchArea, searchType: serviceManager.displayOutput.searchType, isIndoor: false, trajPm: serviceManager.displayOutput.trajectoryPm, trajOg: serviceManager.displayOutput.trajectoryOg)
            }
            displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowPathPixel)
        }
        
        levelCollectionView.reloadData()
    }
    
}

extension OlympusFusionViewController : UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        levels[currentBuilding]!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let levelCollectionView = collectionView.dequeueReusableCell(withReuseIdentifier: LevelCollectionViewCell.className, for: indexPath)
                as? LevelCollectionViewCell else {return UICollectionViewCell()}

        levelCollectionView.setName(level: levels[currentBuilding]![indexPath.row],
                                    isClicked: currentLevel == levels[currentBuilding]![indexPath.row] ? true : false)
        displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowPathPixel)
        
        levelCollectionView.layer.cornerRadius = 15
        levelCollectionView.layer.borderColor = UIColor.darkgrey4.cgColor
        levelCollectionView.layer.borderWidth = 1
        
        return levelCollectionView
    }
}

extension OlympusFusionViewController : UICollectionViewDelegateFlowLayout{
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

extension OlympusFusionViewController: CustomSwitchButtonDelegate {
    func isOnValueChange(isOn: Bool) {
        DispatchQueue.main.async { [self] in
            self.modeAuto = isOn
            if (isOn) {
                self.hideDropDown(flag: true)
                serviceManager = OlympusServiceManager()
                serviceManager.setSimulationMode(flag: false, bleFileName: "ble_lg01.csv", sensorFileName: "sensor_lg01.csv")
                
                var inputMode: String = "auto"
                if (self.sector_id == 6 && self.region != "Canada") {
                    inputMode = "auto"
                } else {
                    inputMode = cardData!.mode
                }
                let uniqueId = self.makeUniqueId(uuid: uuid)
                serviceManager.startService(user_id: uniqueId, region: self.region, sector_id: self.sector_id, service: self.serviceName, mode: inputMode, completion: { isStart, message in
                    if (isStart) {
                        print("(FusionVC) Success : \(message)")
                        serviceManager.addObserver(self)
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
                    self.displayLevelImage(building: currentBuilding, level: currentLevel, flag: isShowPathPixel)
                    self.notificationCenterRemoveObserver()
                    print("(FusionVC) Success : \(isStop.1)")
                    serviceManager.removeObserver(self)
                    self.stopTimer()
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
