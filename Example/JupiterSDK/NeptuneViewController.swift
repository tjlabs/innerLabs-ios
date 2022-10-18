import UIKit
import Charts
import Kingfisher
import JupiterSDK

class NeptuneViewController: UIViewController {
    
    @IBOutlet var NeptuneView: UIView!
    
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    @IBOutlet weak var cardTopImage: UIImageView!
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var contentsView: UIView!
    
    var serviceManager = ServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var userId: String = ""
    
    var RP = [String: [[Double]]]()
    
    var sectorID: Int = 0
    var buildings = [String]()
    var levels = [String: [String]]()
    var levelList = [String]()
    
    var currentBuilding: String = "Unknown"
    var currentLevel: String = "층"
    var pastBuilding: String = "Unknown"
    var pastLevel: String = "Unknown"
    var shakeCount: Int = 0
    var tempLevel = ["B1", "3F", "5F", "7F"]
    
    var isShowRP: Bool = true
    var countTap: Int = 0
    var countShake: Int = 0
    
    var spotImage = UIImage(named: "spotPin")
    
    var limits: [Double] = [-100, 100, -200, 200]
    
    var Spots: [[Double]] = [[-42, -97], [5, -89], [0, -55], [-40, -56], [-70, -23], [-30, -12]]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        setCardData(cardData: cardData!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scatterChart.isHidden = true
        serviceManager.startService(id: userId, sector_id: cardData!.sector_id, service: cardData!.service, mode: cardData!.mode)
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(self.showRP))
        self.sectorNameLabel.addGestureRecognizer(tapRecognizer)
        
        fetchLevel(building: currentBuilding, level: currentLevel, flag: false)
        
        self.hideKeyboardWhenTappedAround()
    }
    
    func setCardData(cardData: CardItemData) {
        self.sectorID = cardData.sector_id
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
    
    private func fetchLevel(building: String, level: String, flag: Bool) {
        // Building -> Level Image Download From URL
        noImageLabel.text = "해당 \(level) 이미지가 없습니다"
        
        // 빌딩 -> 층 이미지 보이기
        if let urlLevel = URL(string: "https://storage.googleapis.com/jupiter_image/map/\(sectorID)/\(building)_\(level).png") {
            let data = try? Data(contentsOf: urlLevel)
            
            if (data != nil) {
                // 빌딩 -> 층 이미지가 있는 경우
                let resourceBuildingLevel = ImageResource(downloadURL: urlLevel, cacheKey: "\(sectorID)_\(building)_\(level)_image")
                
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
                        
                        currentBuilding = "LUPIUM"
                        currentLevel = tempLevel[countShake]
                        countShake += 1
                        if (countShake > 3) {
                            countShake = 0
                        }
                        fetchLevel(building: currentBuilding, level: currentLevel, flag: isShowRP)
                        let randomInt = Int.random(in: 1...9)
                        showSpotContents(id: randomInt)
                        
                        let key = "\(currentBuilding)_\(currentLevel)"
                        let condition: ((String, [[Double]])) -> Bool = {
                            $0.0.contains(key)
                        }
                        let rp: [[Double]] = RP[key] ?? [[Double]]()
//                        drawRP(RP_X: rp[0], RP_Y: rp[1], XY: [0, 0])
                        
                        //-------------//
                        
                        let data = result.spots[bestIndex]
                        if (data.sector_name != "" && data.building_name != "" && data.level_name != "") {
                            
                            if (data.building_name == "") {
                                currentBuilding = buildings[0]
                            } else {
                                currentBuilding = data.building_name
                                if (data.level_name == "") {
                                    currentLevel = levels[currentBuilding]![0]
                                } else {
                                    currentLevel = data.level_name
                                }
                            }
                            
                            if (pastBuilding != currentBuilding || pastLevel != currentLevel) {
                                fetchLevel(building: currentBuilding, level: currentLevel, flag: isShowRP)
                            }
                            
                            pastBuilding = currentBuilding
                            pastLevel = currentLevel
                            
                            let spotNumber: Int = data.spot_number
                            let spotCCS: Double = data.ccs
                            
//                            self.infoSpotLabel.text = String(spotNumber)
//                            self.infoProbLabel.text = String(format: "%.4f", spotCCS)
                            
//                            drawValues(XY: Spots[spotNumber-1])
//                            drawSpot(XY: Spots[spotNumber-1])
//                            showSpotContents(id: spotNumber)
                        } else {
//                            self.infoSpotLabel.text = "Fail"
//                            self.infoProbLabel.text = "0.0000"
                        }
                    }
                } else {
                    self.mainImage.image = UIImage(named: "pinpointMain")
//                    self.infoSpotLabel.text = "Server Fail"
                }
            })
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
    
    func showSpotContents(id: Int) {
//        UIView.animate(withDuration: 0.5) {
//            self.mainView.alpha = 0.0
//            self.contentsView.alpha = 1.0
//        }
        
        let imageName: String = "sf_id_0" + String(id)
        self.mainImage.image = UIImage(named: imageName)
    }

}
