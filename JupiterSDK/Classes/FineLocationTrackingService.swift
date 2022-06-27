import Foundation
import CoreMotion

public class FineLocationTrackingService: NSObject {
    
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
    var mode: String = ""
    
    let G: Double = 9.81
    
    var recentThreshold: Double = 800 // ms
    
    // ----- URL ----- //
    var spatialURL = ""
    var mobileURL = ""
    // --------------- //
    
    // ----- Timer ----- //
    var spatialTimer = Timer()
    var mobileTimer = Timer()
    let SPATIAL_TIMER_INTERVAL: TimeInterval = 1/5 // second
    let MOBILE_TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    let SENSOR_INTERVAL: TimeInterval = 1/200
    // ------------------ //
    
    
    // ----- Sensor Manager ----- //
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    var bleManager = BLECentralManager()
    // -------------------------- //
    
    
    // ----- Spatial Force ----- //
    var spatialPastTime: Double = 0
    var elapsedTime: Double = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    
    public var SPATIAL_INPUT_NUM: Int = 5
    // --------------------- //
    
    
    // ----- Mobile Force ----- //
    var mobilePastTime: Double = 0
    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0
    
    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0
    
    var userAccX: Double = 0
    var userAccY: Double = 0
    var userAccZ: Double = 0
    
    var gravX: Double = 0
    var gravY: Double = 0
    var gravZ: Double = 0
    
    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0
    
    var unitModeInput: Int = 5
    let PDR_INPUT_NUM: Int = 1
    let DR_INPUT_NUM: Int = 5
    // ------------------------ //
    
    
    public var unitDRInfo = UnitDRInfo()
    public var unitDRGenerator = UnitDRGenerator()
    public var unitDistane: Double = 0
    
    // ----- Network ----- //
    var spatialForceArray: [SpatialForce] = [SpatialForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var mobileForceArray: [MobileForce] = [MobileForce(user_id: "", mobile_time: 0, index: 0, length: 0, heading: 0, looking_flag: true)]
    // ------------------- //
    
    public func startService() {
        initialzeSensors()
        startTimer()
        startBLE()
        
        print("JupiterServcie Mode :", mode)
        unitDRGenerator.setMode(mode: mode)
        
        if (mode == "PDR") {
            mobileURL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/calc"
            unitModeInput = PDR_INPUT_NUM
            recentThreshold = 800
        } else if (mode == "DR") {
            mobileURL = "https://where-run-ios-dr-skrgq3jc5a-du.a.run.app/calc"
            unitModeInput = DR_INPUT_NUM
            recentThreshold = 2000
        }
        
        unitDRGenerator.setDRModel()
//        onStartFlag = true
    }
    
    public func stopService() {
        stopTimer()
        stopBLE()
    }
    
    func initialzeSensors() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = accX
                }
                if let accY = data?.acceleration.y {
                    self.accY = accY
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = accZ
                }
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
                }
            }
        }
        
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
        
        motionManager.deviceMotionUpdateInterval = SENSOR_INTERVAL
        motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
            
            if let m = motion {
                self.userAccX = m.userAcceleration.x
                self.userAccY = m.userAcceleration.y
                self.userAccZ = m.userAcceleration.z
                
                self.gravX = m.gravity.x
                self.gravY = m.gravity.y
                self.gravZ = m.gravity.z
                
                self.roll = m.attitude.roll
                self.pitch = m.attitude.pitch
                self.yaw = m.attitude.yaw
            }
        
            if let e = error {
                print(e.localizedDescription)
            }
        }
    }
    
    func startTimer() {
        self.spatialTimer = Timer.scheduledTimer(timeInterval: SPATIAL_TIMER_INTERVAL, target: self, selector: #selector(self.spatialTimerUpdate), userInfo: nil, repeats: true)
        self.mobileTimer = Timer.scheduledTimer(timeInterval: MOBILE_TIMER_INTERVAL, target: self, selector: #selector(self.mobileTimerUpdate), userInfo: nil, repeats: true)
    }

    func stopTimer() {
        self.spatialTimer.invalidate()
        self.mobileTimer.invalidate()
    }
    
    @objc func spatialTimerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
//        let dt = timeStamp - spatialPastTime
        spatialPastTime = timeStamp
        
        var bleDictionary = bleManager.bleFinal
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 mini") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        let data = SpatialForce(user_id: uuid, mobile_time: timeStamp, ble: bleDictionary, pressure: self.pressure)
        spatialForceArray.append(data)
        if ((spatialForceArray.count-1) == SPATIAL_INPUT_NUM) {
            spatialForceArray.remove(at: 0)
            NetworkManager.shared.postSpatialForce(url: spatialURL, input: spatialForceArray)

            spatialForceArray = [SpatialForce(user_id: uuid, mobile_time: 0, ble: [:], pressure: 0)]
        }
    }
    
    @objc func mobileTimerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
//        let dt = timeStamp - mobilePastTime
        mobilePastTime = timeStamp
        
        let data = MobileForce(user_id: uuid, mobile_time: timeStamp, index: 0, length: 0, heading: 0, looking_flag: true)
        mobileForceArray.append(data)
        if ((mobileForceArray.count-1) == unitModeInput) {
            mobileForceArray.remove(at: 0)
            NetworkManager.shared.postMobileForce(url: mobileURL, input: mobileForceArray)

            mobileForceArray = [MobileForce(user_id: uuid, mobile_time: 0, index: 0, length: 0, heading: 0, looking_flag: true)]
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
