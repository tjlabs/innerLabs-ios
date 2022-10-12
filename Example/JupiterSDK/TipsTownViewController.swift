import UIKit
import JupiterSDK
import Floaty

class TipsTownViewController: UIViewController {

    @IBOutlet var TipsTownView: UIView!
    
    @IBOutlet weak var sectorNameLabel: UILabel!
    @IBOutlet weak var cardTopImage: UIImageView!
    
    @IBOutlet weak var buildingLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    @IBOutlet weak var tipsTownScrollView: UIScrollView!
    @IBOutlet weak var tipsTownImage: UIImageView!
    
    var serviceManager = ServiceManager()
    var serviceName = "OSA"
    var userId: String = ""
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    
    var buildings = [String]()
    var levels = [String: [String]]()
    var levelList = [String]()
    
    var currentBuilding: String = "Unknown"
    var currentLevel: String = "Unknown"
    var pastBuilding: String = "Unknown"
    var pastLevel: String = "Unknown"
    
    var runMode: String = ""
    var isOpen: Bool = false
    
    // View
    var defaultHeight: CGFloat = 100
    
    // Floating Button
    let floaty = Floaty()
    
    // Chat
    var window: UIWindow?
    
    // Timer
    var timer: Timer?
    var TIMER_INTERVAL: TimeInterval = 2
    
    override func viewWillAppear(_ animated: Bool) {
        
        setCardData(cardData: cardData!)
        
        if (cardData?.sector_id != 0 && cardData?.sector_id != 7) {
            let firstBuilding: String = (cardData?.infoBuilding[0])!
            let firstBuildingLevels: [String] = (cardData?.infoLevel[firstBuilding])!
            
            levelList = firstBuildingLevels
        }
        
        super.viewWillAppear(false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runMode = cardData!.mode
        
        // Service Manger
        serviceManager.startService(id: userId, sector_id: cardData!.sector_id, service: serviceName, mode: cardData!.mode)
//        self.startTimer()
        
        // Floating Button
//        setFloatingButton()
        
        configureScrollView()
        
        self.hideKeyboardWhenTappedAround()
    }
    
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.stopTimer()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapAuthButton(_ sender: UIButton) {
        getResult()
    }
    
    func setCardData(cardData: CardItemData) {
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
    
    func setFloatingButton() {
        let colorPurple = UIColor(red: 168/255, green: 89/255, blue: 230/255, alpha: 1.0)
        
        floaty.buttonColor = colorPurple
        floaty.plusColor = .white
//        floaty.itemButtonColor = .white
        floaty.openAnimationType = .slideLeft
        
        let itemToBottom = FloatyItem()
        itemToBottom.buttonColor = colorPurple
        itemToBottom.title = "Chat"
        itemToBottom.titleColor = .black
        itemToBottom.icon = UIImage(named: "chat")
        itemToBottom.handler = { [self] itemToBottom in
            goToChatViewController()
            floaty.close()
        }
        floaty.addItem(item: itemToBottom)
        
        self.view.addSubview(floaty)
    }
    
    
//    func jsonToResult(json: String) -> CoarseLevelDetectionResult {
//        let result = CoarseLevelDetectionResult.init()
//        let decoder = JSONDecoder()
//
//        let jsonString = json
//
//        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
//            return decoded
//        }
//
//        return result
//    }
    
    func jsonToResult(json: String) -> OnSpotAuthorizationResult {
        let result = OnSpotAuthorizationResult.init()
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(OnSpotAuthorizationResult.self, from: data) {
            return decoded
        }

        return result
    }
    
//    func decodeSpot(data: OnSpotAuthorizationResult) -> Void {
//        if let data = j
//    }
    
    func getResult() {
        serviceManager.getResult(completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = decodeOSA(json: returnedString)
                print(result)
//                print(result.count)
                
//                if (result.building_name != "") {
//                    self.pastBuilding = currentBuilding
//                    self.pastLevel = currentLevel
//
//                    self.buildingLabel.text = result.building_name
//                    self.levelLabel.text = result.level_name
//
//                    self.currentBuilding = result.building_name
//                    self.currentLevel = result.level_name
//                } else {
//
//                    DispatchQueue.main.async {
//                        self.buildingLabel.text = "Empty"
//                        self.levelLabel.text = "Empty"
//                    }
//                }
            }
        })
    }
    
    func goToChatViewController() {
        window = UIWindow(frame: UIScreen.main.bounds)
        
//        let ratio = UIScreen.main.bounds.height/UIScreen.main.bounds.width
//        let width = (UIScreen.main.bounds.width/2)
//        let height = width*ratio
//
//        let x = width - 30
//        let y = height - 60
//        window = UIWindow(frame: CGRect(x: x, y: y, width: width, height: height))
        
//        AppController.shared.show(in: window)
    }
    
    func startTimer() {
        if (timer == nil) {
            timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        }
    }
    
    @objc func timerUpdate() {
        getResult()
        
        if (self.pastBuilding != self.currentBuilding) {
            // Building Changed
            print("(Building) Past : \(self.pastBuilding)  ->  Current : \(self.currentBuilding)")
            
            
            if (self.pastLevel != self.currentLevel) {
                // Level Changed
                print("(Level) Past : \(self.pastLevel)  ->  Current : \(self.currentLevel)")
            }
        }
    }
    
    func stopTimer() {
        if (timer != nil) {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func configureScrollView() {
        tipsTownImage.image = UIImage(named: "tipsTown")
        tipsTownScrollView.delegate = self
        tipsTownScrollView.zoomScale = 1.0
        tipsTownScrollView.minimumZoomScale = 1.0
        tipsTownScrollView.maximumZoomScale = 2.0
    }
}

extension TipsTownViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
         return self.tipsTownImage
     }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.zoomScale <= 1.0 {
            scrollView.zoomScale = 1.0
            self.tipsTownImage.image = UIImage(named: "tipsTown")
        }
            
        if scrollView.zoomScale >= 2.0 {
            scrollView.zoomScale = 2.0
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveLinear, animations: {
                self.tipsTownImage.image = UIImage(named: "L1_1F")
                scrollView.zoomScale = 1.0
            })
        }
    }
}

