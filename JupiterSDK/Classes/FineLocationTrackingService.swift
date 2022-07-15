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
    var sector_id: Int = 0
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    var mode: String = ""
    
    let G: Double = 9.81
    
    var recentThreshold: Double = 800 // ms
    
    // ----- Timer ----- //
    var receivedForceTimer: Timer?
    var userVelocityTimer: Timer?
    let RF_TIMER_INTERVAL: TimeInterval = 1/5 // second
    let UV_TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    let SENSOR_INTERVAL: TimeInterval = 1/200
    // ------------------ //
    
    
    // ----- Sensor Manager ----- //
    var sensorData = SensorData()
    
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    var bleManager = BLECentralManager()
    // -------------------------- //
    
    
    // ----- Spatial Force ----- //
    var spatialPastTime: Int = 0
    var elapsedTime: Int = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    
    public var SPATIAL_INPUT_NUM: Int = 5
    // --------------------- //
    
    
    // ----- Mobile Force ----- //
    var mobilePastTime: Int = 0
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
    let PDR_INPUT_NUM: Int = 5
    let DR_INPUT_NUM: Int = 10
    // ------------------------ //
    
    
    public var unitDRInfo = UnitDRInfo()
    public var unitDRGenerator = UnitDRGenerator()
    public var unitDistane: Double = 0
    
    var onStartFlag: Bool = false
    
    // ----- Network ----- //
    var receivedForceArray: [ReceivedForce] = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var userVelocityArray: [UserVelocity] = [UserVelocity(user_id: "", mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
    
    var fineLocationTracking = FineLocationTrackingResult(mobile_time: 0, building_name: "", level_name: "", scc: 0, scr: 0, x: 0, y: 0, absolute_heading: 0, phase: 0, calculated_time: 0)
    // ------------------- //
    
    public func startService(id: String, sector_id: Int, mode: String) {
        self.uuid = id
        self.sector_id = sector_id
        self.mode = mode
        
        initialzeSensors()
        startTimer()
        startBLE()
        
        unitDRGenerator.setMode(mode: mode)
        
        if (mode == "pdr") {
            unitModeInput = PDR_INPUT_NUM
            recentThreshold = 800
        } else if (mode == "dr") {
            unitModeInput = DR_INPUT_NUM
            recentThreshold = 2000
        }
        
        unitDRGenerator.setDRModel()
        
        onStartFlag = true
    }
    
    public func stopService() {
        stopTimer()
        stopBLE()
        
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
        if (receivedForceTimer == nil) {
            receivedForceTimer = Timer.scheduledTimer(timeInterval: RF_TIMER_INTERVAL, target: self, selector: #selector(self.receivedForceTimerUpdate), userInfo: nil, repeats: true)
        }
        
        if (userVelocityTimer == nil) {
            userVelocityTimer = Timer.scheduledTimer(timeInterval: UV_TIMER_INTERVAL, target: self, selector: #selector(self.userVelocityTimerUpdate), userInfo: nil, repeats: true)
        }
    }

    func stopTimer() {
        if (receivedForceTimer != nil) {
            receivedForceTimer!.invalidate()
            receivedForceTimer = nil
        }
        
        if (userVelocityTimer != nil) {
            userVelocityTimer!.invalidate()
            userVelocityTimer = nil
        }
    }
    
    @objc func receivedForceTimerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        spatialPastTime = timeStamp
        
        var bleDictionary = bleManager.bleFinal
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 mini") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        let data = ReceivedForce(user_id: uuid, mobile_time: timeStamp, ble: bleDictionary, pressure: self.pressure)
        receivedForceArray.append(data)
        if ((receivedForceArray.count-1) == SPATIAL_INPUT_NUM) {
            receivedForceArray.remove(at: 0)
            NetworkManager.shared.putReceivedForce(url: RF_URL, input: receivedForceArray)

            receivedForceArray = [ReceivedForce(user_id: uuid, mobile_time: 0, ble: [:], pressure: 0)]
        }
    }
    
    @objc func userVelocityTimerUpdate() {
        let timeStamp = getCurrentTimeInMilliseconds()
        mobilePastTime = timeStamp
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        if (unitDRInfo.isIndexChanged) {
            let data = UserVelocity(user_id: uuid, mobile_time: timeStamp, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, looking: unitDRInfo.lookingFlag)
            
            userVelocityArray.append(data)
            if ((userVelocityArray.count-1) == unitModeInput) {
                userVelocityArray.remove(at: 0)
                NetworkManager.shared.putUserVelocity(url: UV_URL, input: userVelocityArray)
                
                var lengthSum: Double = 0
                for idx in 0..<userVelocityArray.count {
                    lengthSum += userVelocityArray[idx].length
                }
                unitDistane = lengthSum

                userVelocityArray = [UserVelocity(user_id: uuid, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                
                getFineLocation()
            }
        }
        
    }
    
    func getResult() -> FineLocationTrackingResult {
        return self.fineLocationTracking
    }
    
    internal func getFineLocation() {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        let input = FineLocationTracking(user_id: uuid, mobile_time: currentTime, sector_id: sector_id)
        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
            let result = jsonToResult(json: returnedString)
            
            self.fineLocationTracking = result
        })
    }

    func startBLE() {
        bleManager.startScan(option: .Foreground)
    }

    func stopBLE() {
        bleManager.stopScan()
    }

    func getCurrentTimeInMilliseconds() -> Int
    {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    func jsonToResult(json: String) -> FineLocationTrackingResult {
        let result = FineLocationTrackingResult(mobile_time: 0, building_name: "", level_name: "", scc: 0, scr: 0, x: 0, y: 0, absolute_heading: 0, phase: 0, calculated_time: 0)
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingResult.self, from: data) {
            return decoded
        }

        return result
    }
}
