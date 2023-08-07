import UIKit
import JupiterSDK

protocol SampleViewPageDelegate {
    func sendPage(data: Int)
}

class SampleViewController: UIViewController, Observer {
    
    @IBOutlet weak var buildingLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    
    var delegate : SampleViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    var sector_id: Int = 0
    var uuid: String = ""
    var runMode: String = ""
    var region: String = ""
    
    let serviceManager = ServiceManager()
    
    var timer: Timer?
    var TIMER_INTERVAL: TimeInterval = 1/20 // second
    
    var isStart: Bool = false
    
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
        default:
            print(localTime + " , (JupiterVC) Default Flag")
        }
    }
    
    func update(result: FineLocationTrackingResult) {
        DispatchQueue.main.async {
            let localTime: String = getLocalTimeString()
            self.buildingLabel.text = result.building_name
            self.levelLabel.text = result.level_name
            self.xLabel.text = String(result.x)
            self.yLabel.text = String(result.y)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        setCardData(cardData: cardData!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        serviceManager.addObserver(self)
        self.startTimer()
    }
    
    func setCardData(cardData: CardItemData) {
        self.sector_id = cardData.sector_id
        self.runMode = cardData.mode
    }
    
    func startTimer() {
        if (timer == nil) {
            timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        if (timer != nil) {
            timer!.invalidate()
            timer = nil
        }
    }
    
    @objc func timerUpdate() {
        if (!self.isStart) {
            serviceManager.startService(id: "tjlabs_sample", sector_id: 6, service: "FLT", mode: "auto", completion: { isStart, message in
                if (isStart) {
                    print(getLocalTimeString() + " , (JupiterVC) Success : \(message)")
                    self.isStart = true
                } else {
                    print(getLocalTimeString() + " , (JupiterVC) Fail : \(message)")
                }
            })
        }
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        serviceManager.removeObserver(self)
        serviceManager.stopService()
        
        self.stopTimer()
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
}
