import UIKit
import Charts
import ExpyTableView
import Kingfisher
import JupiterSDK

class NeptuneViewController: UIViewController, ExpyTableViewDelegate, ExpyTableViewDataSource {
    
    @IBOutlet var NeptuneView: UIView!
    
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var displayViewHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    @IBOutlet weak var cardTopImage: UIImageView!
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var noImageLabel: UILabel!

    @IBOutlet weak var containerTableView: ExpyTableView!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    
    var serviceManager = ServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var userId: String = ""
    
    var RP = [String: [[Double]]]()
    
    var sectorId: Int = 0
    var buildings = [String]()
    var levels = [String: [String]]()
    var levelList = [String]()
    
    var resultToDisplay = Spot()
    
    var currentBuilding: String = "Unknown"
    var currentLevel: String = "층"
    var pastBuilding: String = "Unknown"
    var pastLevel: String = "Unknown"
    var shakeCount: Int = 0
    
    var isShowRP: Bool = false
    var countTap: Int = 0
    var countShake: Int = 0
    
    var spotImage = UIImage(named: "spotPin")
    
    var limits: [Double] = [-100, 100, -200, 200]
    
    var tempLevel = ["B1", "3F", "5F", "7F"]
    var tempCoord: [[Int]] = [[-42, -97], [5, -89], [0, -55], [-40, -56], [-70, -23], [-30, -12]]
    
    var isShow: Bool = false
    var isRadioMap: Bool = false
    var isOpen: Bool = false
    
    // View
    var defaultHeight: CGFloat = 100

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        setCardData(cardData: cardData!)
        
        fixChartHeight(flag: true)
        makeDelegate()
        registerXib()
        showContainerTableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scatterChart.isHidden = true
        serviceManager.startService(id: userId, sector_id: cardData!.sector_id, service: cardData!.service, mode: cardData!.mode)
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(self.showRP))
        self.sectorNameLabel.addGestureRecognizer(tapRecognizer)
        
        self.hideKeyboardWhenTappedAround()
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorId = cardData.sector_id
        self.sectorNameLabel.text = cardData.sector_name
        
        let imageName: String = cardData.cardColor + "CardTop"
        self.cardTopImage.image = UIImage(named: imageName)!
        
        self.buildings = cardData.infoBuilding
        self.levels = cardData.infoLevel
        
        let numBuildings: Int = cardData.infoBuilding.count
        for building in 0..<numBuildings {
            let buildingName: String = cardData.infoBuilding[building]
            let levels: [String] = cardData.infoLevel[buildingName]!
            let numLevels: Int = levels.count
            
            for level in 0..<numLevels {
                let levelName: String = levels[level]
                
                let key: String = "\(buildingName)_\(levelName)"
                let rpXY = loadRP(fileName: key)
                if (!rpXY.isEmpty) {
                    RP[key] = rpXY
                }
            }
        }
        
        let initBuilding = self.buildings[0]
        let initLevels = self.levels[initBuilding]
        let initLevel = initLevels![0]
        self.fetchLevel(building: initBuilding, level: initLevel, flag: false)
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
            
            let xMin = rpXY[0].min()!
            let xMax = rpXY[0].max()!
            let yMin = rpXY[1].min()!
            let yMax = rpXY[1].max()!
//            print("Min Max : \(xMin), \(xMax), \(yMin), \(yMax)")
            
        } catch {
            print("Error reading .csv file")
        }
        
        return rpXY
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
    
    func fixChartHeight(flag: Bool) {
        if (flag) {
            let ratio: Double = 114900 / 68700
            displayViewHeight.constant = displayView.bounds.width * ratio

            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0

            defaultHeight = NeptuneView.bounds.height - 100 - displayViewHeight.constant - bottomPadding

            containerViewHeight.constant = defaultHeight
        } else {
            displayViewHeight.constant = 480
            containerViewHeight.constant = 150
        }
    }
    
    func showContainerTableView() {
        containerViewHeight.constant = 220
    }
    
    func hideContainerTableView() {
        containerViewHeight.constant = defaultHeight
    }
    
    private func fetchLevelTest(building: String, level: String) {
//        noImageLabel.text = "해당 \(level) 이미지가 없습니다"
        noImageLabel.isHidden = true
        imageLevel.isHidden = false
        
        let imageName: String = building + "_" + level + "_FLOOR"
        self.imageLevel.image = UIImage(named: imageName)
    }
    
    private func fetchLevel(building: String, level: String, flag: Bool) {
        // Building -> Level Image Download From URL
        noImageLabel.text = "해당 \(level) 이미지가 없습니다"
        print("Fetch Level : \(building)_\(level)")
        
        // 빌딩 -> 층 이미지 보이기
        if let urlLevel = URL(string: "https://storage.googleapis.com/jupiter_image/map/\(sectorId)/\(building)_\(level).png") {
            let data = try? Data(contentsOf: urlLevel)
            
            if (data != nil) {
                // 빌딩 -> 층 이미지가 있는 경우
                let resourceBuildingLevel = ImageResource(downloadURL: urlLevel, cacheKey: "\(sectorId)_\(building)_\(level)_image")
                
//                scatterChart.isHidden = false
                imageLevel.isHidden = false
                noImageLabel.isHidden = true
                imageLevel.kf.setImage(with: resourceBuildingLevel, placeholder: nil, options: [.transition(.fade(0.8))], completionHandler: nil)
            } else {
                // 빌딩 -> 층 이미지가 없는 경우
                if (flag) {
//                    scatterChart.isHidden = false
                    imageLevel.isHidden = false
                    noImageLabel.isHidden = true
                    
                    imageLevel.image = UIImage(named: "emptyLevel")
                } else {
                    scatterChart.isHidden = true
                    imageLevel.isHidden = true
                    noImageLabel.isHidden = false
                }
                
            }
        } else {
            // 빌딩 -> 층 이미지가 없는 경우
            if (flag) {
//                scatterChart.isHidden = false
                imageLevel.isHidden = false
                noImageLabel.isHidden = true
                
                imageLevel.image = UIImage(named: "emptyLevel")
            } else {
                scatterChart.isHidden = true
                imageLevel.isHidden = true
                noImageLabel.isHidden = false
            }
        }
    }
    

    @IBAction func tapBackButton(_ sender: UIButton) {
        goToBack()
    }
    
    func goToBack() {
        serviceManager.stopService()
        
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapShowButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, delay: 0.01, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.5, delay: 0.01, options: .curveLinear, animations: {
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
    
    func makeDelegate() {
        containerTableView.dataSource = self
        containerTableView.delegate = self
        containerTableView.bounces = false
    }
    
    func registerXib() {
        let spotNib = UINib(nibName: "SpotTableViewCell", bundle: nil)
        containerTableView.register(spotNib, forCellReuseIdentifier: "SpotTableViewCell")
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            
            // Request Result
            serviceManager.getResult(completion: { [self] statusCode, returnedString in
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
                        
                        // --- Test For LUPIUM --- //
                        
                        self.currentBuilding = "LUPIUM"
                        self.currentLevel = "B1"
                        let coord: [Int] = self.tempCoord[countShake]
                        countShake += 1
                        if (countShake > (self.tempCoord.count-1)) {
                            countShake = 0
                        }
                        var data = result.spots[bestIndex]
                        data.spot_x = coord[0]
                        data.spot_y = coord[1]
                        
//                        let randomInt = Int.random(in: 1...9)
//                        showSpotContents(data: <#T##Spot#>)
                        
//                        let key = "\(currentBuilding)_\(currentLevel)"
//                        let condition: ((String, [[Double]])) -> Bool = {
//                            $0.0.contains(key)
//                        }
//                        let rp: [[Double]] = RP[key] ?? [[Double]]()
//                        drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [0, 0])
                        
                        // --- Test For LUPIUM --- //
                        
//                        let data = result.spots[bestIndex]
                        
                        // Check Building or Level Changed
//                        let isChanged: Bool = checkBuildingLevelChanged(data: data)
                        let isChanged: Bool = true
                        if (isChanged) {
//                            fetchLevelTest(building: self.currentBuilding, level: self.currentLevel)
                            fetchLevel(building: self.currentBuilding, level: self.currentLevel, flag: true)
                        }
                        
                        showOSAResult(data: data)
                    }
                } else {
                    self.scatterChart.isHidden = true
                    self.resultToDisplay.building_name = "Unvalid"
                    self.resultToDisplay.spot_name = "Unvalid"
                    self.resultToDisplay.structure_feature_id = 0
                    self.resultToDisplay.ccs = 0.0
                    if (self.isOpen) {
                        UIView.performWithoutAnimation { self.containerTableView.reloadSections(IndexSet(0...0), with: .none) }
                    }
                }
            })
        }
    }
    
    func checkBuildingLevelChanged(data: Spot) -> Bool {
        if (data.sector_name != "" && data.building_name != "" && data.level_name != "") {
            if (data.building_name == "") {
                self.currentBuilding = buildings[0]
            } else {
                self.currentBuilding = data.building_name
                if (data.level_name == "") {
                    self.currentLevel = levels[currentBuilding]![0]
                } else {
                    self.currentLevel = data.level_name
                }
            }
            
            if (self.pastBuilding != self.currentBuilding || self.pastLevel != self.currentLevel) {
//                fetchLevel(building: self.currentBuilding, level: self.currentLevel, flag: isShowRP)
                fetchLevelTest(building: self.currentBuilding, level: self.currentLevel)
            }
            self.pastBuilding = self.currentBuilding
            self.pastLevel = self.currentLevel
            
            return true
        }
        
        return false
    }
    
    func showOSAResult(data: Spot) {
        let spotX = Double(data.spot_x)
        let spotY = Double(data.spot_y)
        let XY: [Double] = [spotX, spotY]
        
        self.resultToDisplay = data
        drawValues(XY: XY)
        drawSpot(XY: XY)
            
        if (self.isOpen) {
            UIView.performWithoutAnimation { self.containerTableView.reloadSections(IndexSet(0...0), with: .none) }
        }
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
        set1.drawValuesEnabled = false
        set1.setScatterShape(.square)
        set1.setColor(UIColor.yellow)
        set1.scatterShapeSize = 4
        
        let set2 = ScatterChartDataSet(entries: values2, label: "User")
        set2.drawValuesEnabled = false
        set2.setScatterShape(.circle)
        set2.setColor(UIColor.systemRed)
        set2.scatterShapeSize = 14
        
        let chartData = ScatterChartData(dataSet: set1)
        chartData.append(set2)
        
        let xMin = limits[0]
        let xMax = limits[1]
        let yMin = limits[2]
        let yMax = limits[3]
        
        let chartFlag: Bool = false
        scatterChart.isHidden = false
        
        // Configure Chart
        scatterChart.xAxis.axisMinimum = xMin-5
        scatterChart.xAxis.axisMaximum = xMax+5
        scatterChart.leftAxis.axisMinimum = yMin-5
        scatterChart.leftAxis.axisMaximum = yMax+5
        
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
    
    private func drawValues(XY: [Double]) {
        let values = (0..<1).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: XY[0], y: XY[1])
        }
        
        let set = ScatterChartDataSet(entries: values, label: "User")
        set.drawValuesEnabled = false
        set.setScatterShape(.circle)
        set.setColor(UIColor.black)
        set.scatterShapeSize = 10
        let chartData = ScatterChartData(dataSet: set)
        
        let xMin = limits[0]
        let xMax = limits[1]
        let yMin = limits[2]
        let yMax = limits[3]
        
        let chartFlag: Bool = false
        scatterChart.isHidden = false
        
        // Configure Chart
        scatterChart.xAxis.axisMinimum = xMin-5
        scatterChart.xAxis.axisMaximum = xMax+5
        scatterChart.leftAxis.axisMinimum = yMin-5
        scatterChart.leftAxis.axisMaximum = yMax+5
        
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
    
    private func drawSpot(XY: [Double]) {
        scatterChart.isHidden = false
        
        let point = scatterChart.getPosition(entry: ChartDataEntry(x: XY[0], y: XY[1]), axis: .left)
        let imageView = UIImageView(image: spotImage?.resize(newWidth: 40))
        imageView.frame = CGRect(x: point.x-15, y: point.y-35, width: 30, height: 30)
        imageView.contentMode = .center
        imageView.tag = 100
        if let viewWithTag = scatterChart.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
        UIView.animate(withDuration: 0.5) {
            self.scatterChart.addSubview(imageView)
        }
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
        }
        return cell
    }
}

extension NeptuneViewController: UITableViewDelegate {
    // 높이 지정 index별
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 40
        } else {
            if (indexPath.section == 0) {
                return 160 + 20
            } else {
                return 120 + 20
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            print("\(indexPath.section)섹션 \(indexPath.row)로우 선택됨")
    }
}

extension NeptuneViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let spotTVC = tableView.dequeueReusableCell(withIdentifier: SpotTableViewCell.identifier) as! SpotTableViewCell
            spotTVC.backgroundColor = .systemGray6
            spotTVC.updateResult(data: resultToDisplay)
            return spotTVC
        } else {
            let robotTVC = tableView.dequeueReusableCell(withIdentifier: RobotTableViewCell.identifier) as!
            RobotTableViewCell
                
            robotTVC.backgroundColor = .systemGray6
            
            return robotTVC
        }
    }
}
