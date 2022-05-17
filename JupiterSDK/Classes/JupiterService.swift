import Foundation
import CoreMotion
import CoreLocation

import FirebaseCore
import FirebaseMLCommon
import FirebaseMLModelInterpreter
import TFLTensorFlowLite

public class JupiterService: NSObject {
    
//    let url = "https://where-run-kr-6qjrrjlaga-an.a.run.app/calc"
    let url = "https://where-run-fire-skrgq3jc5a-du.a.run.app/calc"
    
    // Sensor //
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    
    let PDR_INPUT_NUM: Int = 1
    let DR_INPUT_NUM: Int = 5
    
    let G: Double = 9.81
    
    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0
    
    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    
    var altitude: Double = 0 // relative
    var pressure: Double = 0
    
    var userAccX: Double = 0
    var userAccY: Double = 0
    var userAccZ: Double = 0
    
    var gravX: Double = 0
    var gravY: Double = 0
    var gravZ: Double = 0
    
    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0
    
    var pastTime: Double = 0
    var elapsedTime: Double = 0
    
//    var inputArray = postInput(inputs: [Input()])
    var inputArray: [Input] = [Input(user_id: "", index: 0, length: 0, heading: 0, pressure: 0, looking_flag: false, ble: [:], mobile_time: 0, device_model: "", os_version: 0)]
    
    public var sensorData = SensorData()
    public var unitDRInfo = UnitDRInfo()
    public var jupiterOutput = Output(mobile_time: 0, index: 0, building: "", level: "", x: 0, y: 0, scc: 0, scr: 0, phase: 0, calculated_time: 0)
    
    public var testQueue = LinkedList<TimestampDouble>()
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    let SENSOR_INTERVAL: TimeInterval = 1/200
    
    // Bluetooth //
    let defaults = UserDefaults.standard
    var bleManager = BLECentralManager()
    var bleRSSI: Int = 0
    
    var bleList = BLEList()
    
    var timerBle = Timer()
    var timerBleTimeOut: Int = 10
    let SCAN_INTERVAL: TimeInterval = 30
    
    var parent: UIViewController?
    let unitDRGenerator = UnitDRGenerator()
    
    public var unitModeInput: Int = 0
    
    // To Server //
//    let networkManager = NetworkManager()
//    public var jupiterResult: Output = Output(mobile_time: 0, index: 0, building: "", level: "", x: 0, y: 0, scc: 0, scr: 0, phase: 0, calculated_time: 0)
    
    public var uuid: String = ""
    public var deviceModel: String = ""
    public var os: String = ""
    public var osVersion: Int = 0
    public var mode: String = ""
    var onStartFlag: Bool = false
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveBluetoothNotification), name: .scanInfo, object: nil)
        
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        print("Device Model : \(deviceModel)")
        osVersion = Int(arr[0]) ?? 0
        print("OS : \(osVersion)")
    }
    
    public func startService(parent: UIViewController) {
        self.parent = parent
        if motionManager.isDeviceMotionAvailable {
            initialzeSensors()
            startTimer()
            startBLE()
            
            print("JupiterServcie Mode :", mode)
            unitDRGenerator.setMode(mode: mode)
            
            if (mode == "PDR") {
                unitModeInput = PDR_INPUT_NUM
            } else if (mode == "DR") {
                unitModeInput = DR_INPUT_NUM
            }
            
            unitDRGenerator.setDRModel()
            onStartFlag = true
        }
        else {
            print("DeviceMotion unavailable")
        }
    }
    
    public func stopService() {
        unitDRInfo = UnitDRInfo()
        onStartFlag = false
    }
    
    public func initialzeSensors() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = accX
                    sensorData.acc[0] = accX*G
                }
                if let accY = data?.acceleration.y {
                    self.accY = accY
                    sensorData.acc[1] = accY*G
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = accZ
                    sensorData.acc[2] = accZ*G
                }
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
                    sensorData.gyro[0] = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
                    sensorData.gyro[1] = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
                    sensorData.gyro[2] = gyroZ
                }
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    self.magX = magX
                    sensorData.mag[0] = magX
                }
                if let magY = data?.magneticField.y {
                    self.magY = magY
                    sensorData.mag[1] = magY
                }
                if let magZ = data?.magneticField.z {
                    self.magZ = magZ
                    sensorData.mag[2] = magZ
                }
            }
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = Double(pressure)*10
                    self.pressure = pressure_
                    sensorData.pressure[0] = pressure_
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
                
                sensorData.userAcc[0] = m.userAcceleration.x
                sensorData.userAcc[1] = m.userAcceleration.y
                sensorData.userAcc[2] = m.userAcceleration.z
                
                sensorData.att[0] = m.attitude.roll
                sensorData.att[1] = m.attitude.pitch
                sensorData.att[2] = m.attitude.yaw
            }
        
            if let e = error {
                print(e.localizedDescription)
            }
        }
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        
        timerCounter = 0
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
    
    @objc func timerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        let sensor = checkSensorData(sensorData: sensorData)
        
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        elapsedTime += dt
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        if (unitDRInfo.isIndexChanged) {
//            let bleTest = bleList.bleList.devices
//            let bleDictionary = Dictionary(uniqueKeysWithValues: bleTest.map { ($0.ward_id, $0.rssi) })
            
            let bleDictionary = bleManager.bleFinal
            
            var data = Input(user_id: uuid, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, pressure: sensorData.pressure[0], looking_flag: unitDRInfo.lookingFlag, ble: bleDictionary, mobile_time: timeStamp, device_model: deviceModel, os_version: osVersion)
            
            inputArray.append(data)
            if ((inputArray.count-1) == unitModeInput) {
                inputArray.remove(at: 0)
                NetworkManager.shared.postInput(url: url, input: inputArray)
//                print("Input Array: ", inputArray)
//                print("Input Array Count: ", inputArray.count)
                
                inputArray = [Input(user_id: "", index: 0, length: 0, heading: 0, pressure: 0, looking_flag: false, ble: [:], mobile_time: 0, device_model: "", os_version: 0)]
            }
        }
        jupiterOutput = NetworkManager.shared.jupiterResult
    }
    
    func startBLE() {
        bleManager.startScan(option: .Foreground)
//        startBleTimer()
    }
    
    func stopBLE() {
        bleManager.stopScan()
//        stopBleTimer()
    }
    
//    func startBleTimer() {
//        self.timerBle = Timer.scheduledTimer(timeInterval: SCAN_INTERVAL, target: self, selector: #selector(self.timerBleUpdate), userInfo: nil, repeats: true)
//
//        timerCounter = 0
//    }
//
//    func stopBleTimer() {
//        self.timerBle.invalidate()
//    }
//
//    @objc func timerBleUpdate() {
//        let timeStamp = Date().timeIntervalSince1970.rounded()
//
//        let bleData = KeyStamp(fingerprints: bleList.bleList.devices, mobile_time: timeStamp)
//        print(bleData)
//
//        let d = UploadData(units: [t])
//
//        NetworkManager.shared.uploadData(data: d, completion: {statusCode, returnString in
//
//            self.bleList.resetList()
//        })
//    }
    
    @objc func onDidReceiveBluetoothNotification(_ notification: Notification) {
        if notification.name == .bluetoothReady {
            bleManager.startScan(option: .Foreground)
        }
        
        if notification.name == .scanInfo {
            
            if let data = notification.userInfo as? [String: String]
            {
                let deviceID = data["DeviceID"]!
                let rssi = data["RSSI"]
                
                bleRSSI = Int(rssi!)!
                
                let bleData = FingerPrint(ward_id: deviceID, rssi: bleRSSI)
                bleList.insertDevice(bleData)
            }
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
    
    public func toString() -> String {
        return "acc=\(self.accX), \(self.accY), \(self.accZ) \\ gyro=\(self.gyroX), \(self.gyroY), \(self.gyroZ)"
    }
    
    public func checkSensorData(sensorData: SensorData) -> String {
        return "acc=\(sensorData.acc) \\ gyro=\(sensorData.gyro) // mag=\(sensorData.mag) // att=\(sensorData.att)"
    }
}
