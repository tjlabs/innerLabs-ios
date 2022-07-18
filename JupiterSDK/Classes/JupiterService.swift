import Foundation
import CoreMotion
import CoreLocation
import FirebaseMLModelInterpreter

public class JupiterService: NSObject {
    
    var url = ""
    
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
    
    var inputArray: [Input] = [Input(user_id: "", index: 0, length: 0, heading: 0, pressure: 0, looking_flag: false, ble: [:], mobile_time: 0, device_model: "", os_version: 0)]
    
    public var sensorData = SensorData()
    public var unitDRInfo = UnitDRInfo()
    public var unitDistane: Double = 0
    public var jupiterOutput = Output(x: 0, y: 0, mobile_time: 0, scc: 0, scr: 0, index: 0, search_direction: 0, building: "", level: "", phase: 0, calculated_time: 0)
    
    public var testQueue = LinkedList<TimestampDouble>()
    
    var timer: Timer?
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    let SENSOR_INTERVAL: TimeInterval = 1/200
    
    // Bluetooth //
    var bleManager = BLECentralManager()
    var bleRSSI: Int = 0
    
    var timerBle = Timer()
    var timerBleTimeOut: Int = 10
    let SCAN_INTERVAL: TimeInterval = 30
    
    var parent: UIViewController?
    let unitDRGenerator = UnitDRGenerator()
    
    public var unitModeInput: Int = 0
    
    public var uuid: String = ""
    public var deviceModel: String = ""
    public var os: String = ""
    public var osVersion: Int = 0
    public var mode: String = ""
    var recentThreshold: Double = 800 // ms
    var onStartFlag: Bool = false
    
    public override init() {
        super.init()
        
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
            
            unitDRGenerator.setMode(mode: mode)
            
            if (mode == "pdr") {
//                url = "https://where-run-ios-skrgq3jc5a-du.a.run.app/calc" // iOS
                url = "https://where-run-skrgq3jc5a-du.a.run.app/calc"
                unitModeInput = PDR_INPUT_NUM
                recentThreshold = 800
            } else if (mode == "dr") {
                url = "https://where-run-ios-dr-skrgq3jc5a-du.a.run.app/calc"
                unitModeInput = DR_INPUT_NUM
                recentThreshold = 2000
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
                    sensorData.acc[2] = -accZ*G
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
                
                sensorData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                sensorData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                sensorData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                                
                sensorData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                sensorData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                sensorData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                                
                sensorData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                sensorData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                sensorData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
            }
        
            if let e = error {
                print(e.localizedDescription)
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
//        let sensor = checkSensorData(sensorData: sensorData)
        
        let dt = timeStamp - pastTime
        pastTime = timeStamp
        elapsedTime += dt
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        if (unitDRInfo.isIndexChanged) {
            
            var bleDictionary = bleManager.bleFinal
            
            if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 mini") {
                bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
            }
            
            let data = Input(user_id: uuid, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, pressure: sensorData.pressure[0], looking_flag: unitDRInfo.lookingFlag, ble: bleDictionary, mobile_time: timeStamp, device_model: deviceModel, os_version: osVersion)
            
            inputArray.append(data)
            if ((inputArray.count-1) == unitModeInput) {
                inputArray.remove(at: 0)
                NetworkManager.shared.postInput(url: url, input: inputArray)
                
                var lengthSum: Double = 0
                for idx in 0..<inputArray.count {
                    lengthSum += inputArray[idx].length
                }
                unitDistane = lengthSum
                
                inputArray = [Input(user_id: "", index: 0, length: 0, heading: 0, pressure: 0, looking_flag: false, ble: [:], mobile_time: 0, device_model: "", os_version: 0)]
            }
        }
        let tempOutput = NetworkManager.shared.jupiterResult
        
        if ((timeStamp - tempOutput.mobile_time) < recentThreshold) {
            jupiterOutput = NetworkManager.shared.jupiterResult
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
    
    public func toString() -> String {
        return "acc=\(self.accX), \(self.accY), \(self.accZ) \\ gyro=\(self.gyroX), \(self.gyroY), \(self.gyroZ)"
    }
    
    public func checkSensorData(sensorData: SensorData) -> String {
        return "acc=\(sensorData.acc) \\ gyro=\(sensorData.gyro) // mag=\(sensorData.mag) // att=\(sensorData.att)"
    }
}
