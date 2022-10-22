import UIKit
import SwiftUI
import Charts
import JupiterSDK

class SpotViewController: UIViewController {
    
    @IBOutlet var SpotView: UIView!
    
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var imageLevel: UIImageView!
    @IBOutlet weak var scatterChart: ScatterChartView!
    
    @IBOutlet weak var cardTopImage: UIImageView!
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var contentsView: UIView!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ceoLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoSpotLabel: UILabel!
    @IBOutlet weak var infoProbLabel: UILabel!
    
    var serviceManager = ServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var userId: String = ""
    
    var buildings = [String]()
    var levels = [String: [String]]()
    var levelList = [String]()
    
    var currentBuilding: String = "Unknown"
    var currentLevel: String = "Unknown"
    var pastBuilding: String = "Unknown"
    var pastLevel: String = "Unknown"
    var shakeCount: Int = 0
    
    var countTap: Int = 0
    
    var spotImage = UIImage(named: "spotPin")
    
    var limits: [Double] = [-100, 100, -200, 200]
    
    var Spots: [[Double]] = [[-42, -97], [5, -89], [0, -55], [-40, -56], [-70, -23], [-30, -12]]
    
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
        print(cardData)
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
//        set.setColor(UIColor.systemRed)
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
    
    func showSpotContents(id: Int) {
        UIView.animate(withDuration: 0.5) {
            self.mainView.alpha = 0.0
            self.contentsView.alpha = 1.0
        }
        
        switch(id) {
        case 1:
            UIView.animate(withDuration: 0.5) {
                self.mainImage.image = UIImage(named: "S3_7F_ELEV")
                self.locationLabel.text = "엘레베이터 앞"
                self.typeLabel.text = "출입관련"
                self.ceoLabel.text = "해당없음"
                self.companyLabel.text = "해당없음"
            }
        case 2:
            UIView.animate(withDuration: 0.5) {
                self.mainImage.image = UIImage(named: "S3_7F_DODA")
                self.locationLabel.text = "A, B"
                self.typeLabel.text = "TIPS 창업기업"
                self.ceoLabel.text = "곽도영"
                self.companyLabel.text = "소프트웨어"
            }
        case 3:
            UIView.animate(withDuration: 0.5) {
                self.mainImage.image = UIImage(named: "S3_7F_MEET")
                self.locationLabel.text = "회의실B"
                self.typeLabel.text = "회의공간"
                self.ceoLabel.text = "해당없음"
                self.companyLabel.text = "해당없음"
            }
        case 4:
            UIView.animate(withDuration: 0.5) {
                self.mainImage.image = UIImage(named: "S3_7F_TJLABS")
                self.locationLabel.text = "E"
                self.typeLabel.text = "TIPS 창업기업"
                self.ceoLabel.text = "이택진"
                self.companyLabel.text = "소프트웨어"
            }
        case 5:
            UIView.animate(withDuration: 0.5) {
                self.mainImage.image = UIImage(named: "S3_7F_TJLABS")
                self.locationLabel.text = "E의 A위치"
                self.typeLabel.text = "사무공간"
                self.ceoLabel.text = "이택진"
                self.companyLabel.text = "소프트웨어"
            }
        case 6:
            UIView.animate(withDuration: 0.5) {
                self.mainImage.image = UIImage(named: "S3_7F_TJLABS")
                self.locationLabel.text = "E의 B위치"
                self.typeLabel.text = "사무공간"
                self.ceoLabel.text = "이택진"
                self.companyLabel.text = "소프트웨어"
            }
        default:
            locationLabel.text = ""
            typeLabel.text = ""
            ceoLabel.text = ""
            companyLabel.text = ""
        }
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
                            let spotNumber: Int = data.spot_number
                            let spotCCS: Double = data.ccs
                            
                            self.infoSpotLabel.text = String(spotNumber)
                            self.infoProbLabel.text = String(format: "%.4f", spotCCS)
                            
                            drawValues(XY: Spots[spotNumber-1])
                            drawSpot(XY: Spots[spotNumber-1])
                            showSpotContents(id: spotNumber)
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
