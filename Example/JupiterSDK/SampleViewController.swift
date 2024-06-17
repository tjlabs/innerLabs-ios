import UIKit
import Flutter
//import FlutterPluginRegistrant
import JupiterSDK

protocol SampleViewPageDelegate {
    func sendPage(data: Int)
}

//class SampleViewController: UIViewController, Observer, FlutterStreamHandler {
class SampleViewController: UIViewController, Observer {
    @IBOutlet weak var buildingLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var showMapButton: UIButton!
    
//    lazy var flutterMapViewController: FlutterViewController = {
//        let view = FlutterViewController()
//        return view
//    }()
    
    var delegate : SampleViewPageDelegate?
    
    var cardData: CardItemData?
    var page: Int = 0
    
    var sector_id: Int = 0
    var uuid: String = ""
    var runMode: String = ""
    var region: String = ""
    
    let serviceManager = ServiceManager()
    
    var timer: Timer?
    var TIMER_INTERVAL: TimeInterval = 1 // second
    
    var isStart: Bool = false
    
//    let channelName: String = "com.tjlabscorp.flutter.mapuimodule/fltResult"
//    var events: FlutterEventSink?
//    private var eventChannel: FlutterEventChannel?
    
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
//            print(localTime + " , (JupiterVC) Result = \(result)")
//            self.sendResult(result: result)
            
            self.buildingLabel.text = result.building_name
            self.levelLabel.text = result.level_name
            self.xLabel.text = String(result.x)
            self.yLabel.text = String(result.y)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
//        setCardData(cardData: cardData!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        serviceManager.addObserver(self)
//        self.startTimer()
    }
    
//    func setCardData(cardData: CardItemData) {
//        self.sector_id = cardData.sector_id
//        self.runMode = cardData.mode
//    }
//    
//    func startTimer() {
//        if (timer == nil) {
//            timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
//        }
//    }
//    
//    func stopTimer() {
//        if (timer != nil) {
//            timer!.invalidate()
//            timer = nil
//        }
//    }
//    
//    @objc func timerUpdate() {
//        if (!self.isStart) {
//            serviceManager.startService(id: "tjlabs_sample", sector_id: 9, service: "FLT", mode: "pdr", completion: { isStart, message in
//                if (isStart) {
//                    print(getLocalTimeString() + " , (JupiterVC) Success : \(message)")
//                    self.isStart = true
//                } else {
//                    print(getLocalTimeString() + " , (JupiterVC) Fail : \(message)")
//                }
//            })
//        }
//    }
//    
//    @IBAction func tapBackButton(_ sender: UIButton) {
//        serviceManager.removeObserver(self)
//        serviceManager.stopService()
//       
//        self.stopTimer()
//        self.delegate?.sendPage(data: page)
//        self.removeFlutterMapViewController()
//        self.eventChannel?.setStreamHandler(nil)
//        self.navigationController?.popViewController(animated: true)
//    }
//    
//    func convertResultToNSDict(result: FineLocationTrackingResult) -> NSDictionary {
//        let fineLocationDict: NSDictionary = [
//            "mobile_time": result.mobile_time,
//            "building_name": result.building_name,
//            "level_name": result.level_name,
//            "scc": result.scc,
//            "x": result.x,
//            "y": result.y,
//            "absolute_heading": result.absolute_heading,
//            "phase": result.phase,
//            "calculated_time": result.calculated_time,
//            "index": result.index,
//            "velocity": result.velocity,
//            "mode": result.mode,
//            "ble_only_position": result.ble_only_position,
//            "isIndoor": result.isIndoor
//        ]
//        
//        return fineLocationDict
//    }
//    
//    @IBAction func tapShowMapButton(_ sender: UIButton) {
//        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
//        }) { (success) in
//            sender.isSelected = !sender.isSelected
//            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: {
//                sender.transform = .identity
//            }, completion: nil)
//        }
//        
//        if sender.isSelected == false {
//            self.showMapButton.titleLabel?.text = "Hide Map"
//            self.showFlutterMap()
//        } else {
//            self.showMapButton.titleLabel?.text = "Show Map"
//            self.removeFlutterMapViewController()
//        }
//    }
//    
//    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//        self.events = events
//        return nil
//    }
//
//    func onCancel(withArguments arguments: Any?) -> FlutterError? {
//        self.events = nil
//        return nil
//    }
//    
//    func sendResult(result: FineLocationTrackingResult) {
//        guard let events = self.events else {
//            print(getLocalTimeString() + " , (Flutter) Fail : Send result")
//            return
//        }
//        events (
//            NSDictionary(
//                dictionary: [
//                    "index" : result.index,
//                    "mobileTime": result.mobile_time,
//                    "building": result.building_name,
//                    "level": result.level_name,
//                    "x": Int(result.x),
//                    "y": Int(result.y),
//                    "absoluteHeading": result.absolute_heading
//                    ]
//                )
//        )
//    }
//    
//    private func addFlutterMapViewController() {
//        addChild(flutterMapViewController)
//        flutterMapViewController.view.frame = CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: (self.view.frame.size.height/2))
//        self.view.addSubview(flutterMapViewController.view)
//        flutterMapViewController.didMove(toParent: self)
//    }
//    
//    @objc private func removeFlutterMapViewController() {
//        flutterMapViewController.willMove(toParent: nil)
//        flutterMapViewController.removeFromParent()
//        flutterMapViewController.view.removeFromSuperview()
//    }
//    
//    private func showFlutterMap() {
//        if let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).mapEngine {
//            flutterEngine.viewController = nil
//            self.flutterMapViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
//            self.eventChannel = FlutterEventChannel(name: self.channelName, binaryMessenger: self.flutterMapViewController.binaryMessenger)
//            self.eventChannel?.setStreamHandler(self)
//            self.addFlutterMapViewController()
//        } else {
//            print(getLocalTimeString() + " , (Flutter) Engine is nil")
//        }
//    }
}
