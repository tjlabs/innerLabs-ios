import UIKit
import SwiftUI
import Charts
import Kingfisher
import JupiterSDK

class SpotViewController: UIViewController {
    
    @IBOutlet var SpotView: UIView!
    
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    @IBOutlet weak var cardTopImage: UIImageView!
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var noImageLabel: UILabel!
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var contentsView: UIView!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var spotNameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ccsLabel: UILabel!
    
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoSpotLabel: UILabel!
    @IBOutlet weak var infoProbLabel: UILabel!
    
    var serviceManager = ServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var userId: String = ""
    
    var sector_id: Int = 0
    var buildings = [String]()
    var levels = [String: [String]]()
    var levelList = [String]()
    
    var currentBuilding: String = "Unknown"
    var currentLevel: String = "Unknown"
    var pastBuilding: String = "Unknown"
    var pastLevel: String = "Unknown"
    var shakeCount: Int = 0
    
    var countTap: Int = 0
    let CCS_THRESHOLD: Double = 0.5
    
    var spotImage = UIImage(named: "spotPin")
    
    var limits: [Double] = [-100, 100, -200, 200]
    
    var Spots: [[Double]] = [[-42, -97], [5, -89], [-15, -68], [0, -55], [-40, -56]]
//    var Spots: [[Double]] = [[-42, -97], [5, -89], [0, -55], [-40, -56], [-70, -23], [-30, -12], [-15, -68]]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        setCardData(cardData: cardData!)
        contentsView.alpha = 0.0
        infoView.alpha = 0.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scatterChart.isHidden = true
        serviceManager.startService(id: userId, sector_id: cardData!.sector_id, service: cardData!.service, mode: cardData!.mode)
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(self.showProbability))
        self.sectorNameLabel.addGestureRecognizer(tapRecognizer)
        
        self.hideKeyboardWhenTappedAround()
    }
    
    func setCardData(cardData: CardItemData) {
        self.sector_id = cardData.sector_id
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
        }
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
    
    @objc func showProbability() {
        countTap += 1
        
        if (countTap == 5) {
            UIView.animate(withDuration: 0.5) {
                self.infoView.alpha = 1.0
            }
            self.sectorNameLabel.textColor = .yellow
        } else if (countTap > 9) {
            UIView.animate(withDuration: 0.5) {
                self.infoView.alpha = 0.0
            }
            countTap = 0
            self.sectorNameLabel.textColor = .white
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
    
    func testSpotContents(id: Int) {
        UIView.animate(withDuration: 0.5) {
            self.mainView.alpha = 0.0
            self.contentsView.alpha = 1.0
        }
        
        switch(id) {
        case 1:
            self.mainImage.image = UIImage(named: "sf_id_2")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "엘리베이터"
            self.typeLabel.text = "엘리베이터"
            self.ccsLabel.text = "0.6744"
        case 2:
            self.mainImage.image = UIImage(named: "sf_id_6")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "도다마인드 입구"
            self.typeLabel.text = "출입구"
            self.ccsLabel.text = "0.6744"
        case 3:
            self.mainImage.image = UIImage(named: "sf_id_5")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "회의실 B"
            self.typeLabel.text = "회의실"
            self.ccsLabel.text = "0.6744"
        case 4:
            self.mainImage.image = UIImage(named: "sf_id_6")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "티제이랩스 입구"
            self.typeLabel.text = "출입구"
            self.ccsLabel.text = "0.6744"
        case 5:
            self.mainImage.image = UIImage(named: "sf_id_4")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "티제이랩스 A위치"
            self.typeLabel.text = "사무공간"
            self.ccsLabel.text = "0.6744"
        case 6:
            self.mainImage.image = UIImage(named: "sf_id_4")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "티제이랩스 B위치"
            self.typeLabel.text = "사무공간"
            self.ccsLabel.text = "0.6744"
        case 7:
            self.mainImage.image = UIImage(named: "sf_id_5")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "회의실 A"
            self.typeLabel.text = "회의실"
            self.ccsLabel.text = "0.6744"
        default:
            self.mainImage.image = UIImage(named: "sf_id_1")
            self.locationLabel.text = "S3 7F"
            self.spotNameLabel.text = "Unknown"
            self.typeLabel.text = "Unknown"
            self.ccsLabel.text = "0.6744"
        }
        drawValues(XY: Spots[id-1])
        drawSpot(XY: Spots[id-1])
    }
    
    func showSpotContents(data: Spot) {
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
            self.mainView.alpha = 0.0
            self.contentsView.alpha = 1.0
        }
        
        let locationName: String = building + " " + level
        let sfImageName: String = "sf_id_\(sfId)"
        self.mainImage.image = UIImage(named: sfImageName)
        
        self.locationLabel.text = locationName
        self.spotNameLabel.text = spotName
        
        var typeName: String = ""
        switch(sfId) {
        case 1:
            typeName = "계단"
        case 2:
            typeName = "엘리베이터"
        case 3:
            typeName = "에스컬레이터"
        case 4:
            typeName = "사무공간"
        case 5:
            typeName = "회의실"
        case 6:
            typeName = "출입구"
        case 7:
            typeName = "탕비실"
        case 8:
            typeName = "프린터"
        case 9:
            typeName = "라운지"
        case 10:
            typeName = "화장실"
        case 11:
            typeName = "책상"
        case 12:
            typeName = "가게"
        case 13:
            typeName = "홀"
        default:
            typeName = "Invalid"
        }
        self.typeLabel.text = typeName
        self.ccsLabel.text = String(format: "%.4f", ccs)
        
        drawValues(XY: [spotX, spotY])
        drawSpot(XY: [spotX, spotY])
    }
    
    private func fetchLevel(building: String, level: String) {
        // Building -> Level Image Download From URL
        noImageLabel.text = "해당 \(level) 이미지가 없습니다"
        let imageName: String = building + "_" + level + "_FLOOR"
        self.imageLevel.image = UIImage(named: imageName)
    }
    
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            // Request Result
            serviceManager.getResult(completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    print(returnedString)
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
                        if (data.sector_name != "" && data.building_name != "" && data.level_name != "") {
                            if (data.ccs >= CCS_THRESHOLD) {
                                // Check Building & Level Change
                                currentBuilding = data.building_name
                                currentLevel = data.level_name
                                
                                if ((pastBuilding != currentBuilding) || (pastLevel != pastLevel)) {
                                    fetchLevel(building: currentBuilding, level: currentLevel)
                                }
                                
                                let spotNumber: Int = data.spot_number
                                let spotCCS: Double = data.ccs
                                
                                self.infoSpotLabel.text = String(spotNumber)
                                self.infoProbLabel.text = String(format: "%.4f", spotCCS)
                                
                                showSpotContents(data: data)
                            } else {
                                self.infoSpotLabel.text = "Fail"
                                self.infoProbLabel.text = "0.0000"
                            }
                            
                        } else {
                            self.infoSpotLabel.text = "Fail"
                            self.infoProbLabel.text = "0.0000"
                        }
                    }
                } else {
                    self.infoSpotLabel.text = "Server Fail"
                    self.infoProbLabel.text = String(statusCode)
                }
            })
        }
    }
}
