import UIKit
import SwiftCSVExport
import JupiterSDK

class Measurements {
    var time: Int = 0

    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0

    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0

    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0

    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0

    var qx: Double = 0
    var qy: Double = 0
    var qz: Double = 0
    var qw: Double = 0

    var pressure: Double = 0

    var ble: String = ""
}

class CollectViewController: UIViewController {
    @IBOutlet var collectView: UIView!
    @IBOutlet weak var bleView: UIView!
    
    
    var serviceManager = ServiceManager()
    
    var delegate : ServiceViewPageDelegate?
    var cardData: CardItemData?
    var page: Int = 0
    var userId: String = ""
    
    var timer: Timer?
    let TIMER_INTERVAL: TimeInterval = 1/40
    
    let data:NSMutableArray  = NSMutableArray()
    
    var saveFlag: Bool = false
    var isWriting: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        let width = collectView.frame.size.width
        let height = collectView.frame.size.height
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        serviceManager.initCollect()
        
        startTimer()
        
        print("CollectView Size :", collectView.frame.size)
    }
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        self.delegate?.sendPage(data: page)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapStartButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.0, delay: 0.0, options: .curveLinear, animations: {
        }) { (success) in
            sender.isSelected = !sender.isSelected
            UIView.animate(withDuration: 0.0, delay: 0.0, options: .curveLinear, animations: {
                sender.transform = .identity
            }, completion: nil)
        }
        
        if sender.isSelected == false {
            sender.backgroundColor = .blue3
            isWriting = true
            
            serviceManager.startCollect()
        }
        else {
            sender.backgroundColor = .systemGray4
            isWriting = false
            
            serviceManager.stopCollect()
        }
    }
    
    func startTimer() {
        if (timer == nil) {
            self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        }
    }

    func stopTimer() {
        if (timer != nil) {
            self.timer!.invalidate()
            self.timer = nil
        }
    }
    
    func startToSave() {
        serviceManager.startCollect()
        saveFlag = true
    }

    func writeData(collectData: CollectData) {
        let time = collectData.time

        let accX = collectData.acc[0]
        let accY = collectData.acc[1]
        let accZ = collectData.acc[2]

        let gyroX = collectData.gyro[0]
        let gyroY = collectData.gyro[1]
        let gyroZ = collectData.gyro[2]

        let magX = collectData.mag[0]
        let magY = collectData.mag[1]
        let magZ = collectData.mag[2]

        let roll = collectData.att[0]
        let pitch = collectData.att[1]
        let yaw = collectData.att[2]

        let qx = collectData.quaternion[0]
        let qy = collectData.quaternion[1]
        let qz = collectData.quaternion[2]
        let qw = collectData.quaternion[3]

        let pressure = collectData.pressure[0]

        let meas = Measurements()

        meas.time = time

        meas.accX = accX
        meas.accY = accY
        meas.accZ = accZ

        meas.gyroX = gyroX
        meas.gyroY = gyroY
        meas.gyroZ = gyroZ

        meas.magX = magX
        meas.magY = magY
        meas.magZ = magZ

        meas.roll = roll
        meas.pitch = pitch
        meas.yaw = yaw

        meas.qx = qx
        meas.qy = qy
        meas.qz = qz
        meas.qw = qw

        meas.pressure = pressure
        
        let bleData = collectData.bleAvg
        let bleString = (bleData.flatMap({ (key, value) -> String in
            let str = String(format: "%.2f", value)
            return "\(key),\(str)"
        }) as Array).joined(separator: ",")
        meas.ble = bleString

        data.add(listPropertiesWithValues(meas))
    }

    @objc func timerUpdate() {
//        print("Sensor :", serviceManager.collectData.acc)
//        print("BLE :", serviceManager.collectData.bleAvg)
        
        if (saveFlag) {
//            writeData(collectData: serviceManager.collectData)
            
            if (serviceManager.collectData.isIndexChanged) {
                print("PDR :",serviceManager.collectData.index)
            }
        }
    }
}
