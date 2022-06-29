import Foundation
import CoreMotion

public class FineLevelDetectionService: NSObject {
    
    public override init() {
        super.init()
        
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        osVersion = Int(arr[0]) ?? 0
    }
    
    var uuid: String = ""
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    
    var unitModeInput: Int = 5
    var recentThreshold: Double = 800 // ms
    
    // ----- URL ----- //
    var url = ""
    // --------------- //
    
    // ----- Timer ----- //
    var timer: Timer?
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/2 // second
    let SENSOR_INTERVAL: TimeInterval = 1/200
    // ------------------ //
    
    
    // ----- Sensor Manager ----- //
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    var bleManager = BLECentralManager()
    // -------------------------- //
    
    
    // ----- Spatial Force ----- //
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    // --------------------- //
    
    
    // ----- Network ----- //
    var inputArray: [SpatialForce] = [SpatialForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    // ------------------- //
    
    public func startService() {
        initialzeSensors()
        startTimer()
        startBLE()
    }
    
    public func stopService() {
        stopTimer()
        stopBLE()
    }
    
    func initialzeSensors() {
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    self.magX = magX
                }
                if let magY = data?.magneticField.y {
                    self.magY = magY
                }
                if let magZ = data?.magneticField.z {
                    self.magZ = magZ
                }
            }
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = Double(pressure)*10
                    self.pressure = pressure_
                }
            }
        }
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
        let timeStamp = getCurrentTimeInMilliseconds()
        
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        elapsedTime += dt
        
        var bleDictionary = bleManager.bleFinal
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 mini") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        let data = SpatialForce(user_id: uuid, mobile_time: timeStamp, ble: bleDictionary, pressure: self.pressure)
        
        inputArray.append(data)
        if ((inputArray.count-1) == unitModeInput) {
            inputArray.remove(at: 0)
            NetworkManager.shared.postSpatialForce(url: url, input: inputArray)

            inputArray = [SpatialForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
        }
    }

    func startBLE() {
        bleManager.startScan(option: .Foreground)
    }

    func stopBLE() {
        bleManager.stopScan()
    }

    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}
