import Foundation
import CoreMotion
import Alamofire

public class ServiceManager: Observation {
    
    var finalOutput = FineLocationTrackingResult()
    
    func tracking(input: FineLocationTrackingResult) {
        for observer in observers {
            var result = input
            
            // Map Matching
            let xy = correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading)
            result.x = xy[0]
            result.y = xy[1]
            result.absolute_heading = -(input.absolute_heading - 90)
            
            // Averaging
            if (!pastResult.isEmpty) {
                result.x = (result.x + pastResult[0])/2
                result.y = (result.y + pastResult[1])/2
                result.absolute_heading = (result.absolute_heading + pastResult[2])/2
            }
            
            // Past Result Update
            if (pastResult.isEmpty) {
                pastResult.append(result.x)
                pastResult.append(result.y)
                pastResult.append(result.absolute_heading)
            } else {
                pastResult[0] = result.x
                pastResult[1] = result.y
                pastResult[2] = result.absolute_heading
            }
            
            observer.update(result: result)
        }
    }
    
    let G: Double = 9.81
    
    var user_id: String = ""
    var sector_id: Int = 0
    var service: String = ""
    var mode: String = ""
    
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    
    var Road = [String: [[Double]]]()
    var RoadHeading = [String: [String]]()
    // ----- Sensor & BLE ----- //
    var sensorData = SensorData()
    public var collectData = CollectData()
    
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    var bleManager = BLECentralManager()
    // ------------------------ //
    
    // ----- Spatial Force ----- //
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    var pressure: Double = 0
    
    var SPATIAL_INPUT_NUM: Int = 7
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
    
    var UV_INPUT_NUM: Int = 2
    var VAR_INPUT_NUM: Int = 5
    var INIT_INPUT_NUM: Int = 2
    // ------------------------ //
    
    
    // ----- Timer ----- //
    var receivedForceTimer: Timer?
    var RF_INTERVAL: TimeInterval = 1/2 // second
    
    var userVelocityTimer: Timer?
    var UV_INTERVAL: TimeInterval = 1/40 // second
    
    let SENSOR_INTERVAL: TimeInterval = 1/200
    
    var collectTimer: Timer?
    var interruptTimer: Timer?
    // ------------------ //
    
    // ----- Network ----- //
    let USER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/user"
    var inputReceivedForce: [ReceivedForce] = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var inputUserVelocity: [UserVelocity] = [UserVelocity(user_id: "", mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
    // ------------------- //
    
    // ----- Fine Location Tracking ----- //
    var unitDRInfo = UnitDRInfo()
    var unitDRGenerator = UnitDRGenerator()
    
    var unitDistane: Double = 0
    var onStartFlag: Bool = false
    
    var recentThreshold: Double = 800 // ms
    
    var preOutputMobileTime: Int = 0
    var preUnitHeading: Double = 0
    
    var floorUpdateRequestTimer: Double = 0
    var floorUpdateRequestFlag: Bool = false
    let FLOOR_UPDATE_REQUEST_TIME: Double = 15
    
    public var displayOutput = ServiceResult()
    // --------------------------------- //
    
    
    // ----------- Kalman Filter ------------ //
    var phase: Int = 0
    
    var timeUpdateFlag: Bool = false
    var measurementUpdateFlag: Bool = false

    var kalmanP: Double = 1
    var kalmanQ: Double = 0.3
    var kalmanR: Double = 3
    var kalmanK: Double = 1

    var updateHeading: Double = 0
    var headingKalmanP: Double = 0.5
    var headingKalmanQ: Double = 0.5
    var headingKalmanR: Double = 1
    var headingKalmanK: Double = 1

    var timeUpdatePosition = KalmanOutput()
    var measurementPosition = KalmanOutput()

    var timeUpdateOutput = FineLocationTrackingResult()
    var measurementOutput = FineLocationTrackingResult()
    
    var pastResult = [Double]()
    public override init() {
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        print("Device Model : \(deviceModel)")
        osVersion = Int(arr[0]) ?? 0
        print("OS : \(osVersion)")
    }
    
    public func initService() {
        initialzeSensors()
        startTimer()
        startBLE()
        
        if (self.service == "FLT") {
            unitDRGenerator.setMode(mode: mode)
            
            if (mode == "pdr") {
                VAR_INPUT_NUM = 5
                recentThreshold = 800
            } else if (mode == "dr") {
                VAR_INPUT_NUM = 10
                recentThreshold = 2000
            }
            
            unitDRGenerator.setDRModel()
            
            onStartFlag = true
        }
    }

    public func startService(id: String, sector_id: Int, service: String, mode: String) {
        self.user_id = id
        self.sector_id = sector_id
        self.service = service
        self.mode = mode
        
        var interval: Double = 1/2
        var numInput = 7
        
        switch(service) {
        case "SD":
            numInput = 7
            interval = 1/2
        case "BD":
            numInput = 7
            interval = 1/2
        case "CLD":
            numInput = 7
            interval = 1/2
        case "FLD":
            numInput = 7
            interval = 1/2
        case "CLE":
            numInput = 7
            interval = 1/2
        case "FLT":
            numInput = 6
            interval = 1/5
        default:
            print("(Error) Fail to initialize the service")
        }
        
        self.SPATIAL_INPUT_NUM = numInput
        self.RF_INTERVAL = interval
        
        self.initService()
        
        let userInfo = UserInfo(user_id: self.user_id, device_model: deviceModel, os_version: osVersion)
        postUser(url: USER_URL, input: userInfo, completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let list = jsonToCardList(json: returnedString)
                let myCard = list.sectors
                
                for card in 0..<myCard.count {
                    let cardInfo: CardInfo = myCard[card]
                    let id: Int = cardInfo.sector_id
                    let buildings_n_levels: [[String]] = cardInfo.building_level
                        
                    var infoBuilding = [String]()
                    var infoLevel = [String:[String]]()
                    for building in 0..<buildings_n_levels.count {
                        let buildingName: String = buildings_n_levels[building][0]
                        let levelName: String = buildings_n_levels[building][1]
                            
                        // Building
                        if !(infoBuilding.contains(buildingName)) {
                            infoBuilding.append(buildingName)
                        }
                            
                        // Level
                        if let value = infoLevel[buildingName] {
                            var levels:[String] = value
                            levels.append(levelName)
                            infoLevel[buildingName] = levels
                        } else {
                            let levels:[String] = [levelName]
                            infoLevel[buildingName] = levels
                        }
                    }
                    
                    if (id == self.sector_id) {
                        let buildings_n_levels: [[String]] = cardInfo.building_level
                            
                        var infoBuilding = [String]()
                        var infoLevel = [String:[String]]()
                        for building in 0..<buildings_n_levels.count {
                            let buildingName: String = buildings_n_levels[building][0]
                            let levelName: String = buildings_n_levels[building][1]
                                
                            // Building
                            if !(infoBuilding.contains(buildingName)) {
                                infoBuilding.append(buildingName)
                            }
                                
                            // Level
                            if let value = infoLevel[buildingName] {
                                var levels:[String] = value
                                levels.append(levelName)
                                infoLevel[buildingName] = levels
                            } else {
                                let levels:[String] = [levelName]
                                infoLevel[buildingName] = levels
                            }
                        }
                        
                        // Key-Value Saved
                        for i in 0..<infoBuilding.count {
                            let buildingName = infoBuilding[i]
                            let levelList = infoLevel[buildingName]
                            for j in 0..<levelList!.count {
                                let levelName = levelList![j]
                                let key: String = "\(buildingName)_\(levelName)"
                                
                                let url = "https://storage.googleapis.com/jupiter_image/rp/ios/\(self.sector_id)/\(key).csv"
                                AF.request(url).response { response in
                                    var statusCode = 404
                                    if let code = response.response?.statusCode {
                                        statusCode = code
                                    }

                                    if (statusCode == 200) {
                                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                            ( self.Road[key], self.RoadHeading[key] ) = self.parseRoad(data: utf8Text)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    public func stopService() {
        stopTimer()
        stopBLE()
        
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
            onStartFlag = false
        }
    }
    
    public func initCollect() {
        unitDRGenerator.setMode(mode: "pdr")
        
        initialzeSensors()
        startCollectTimer()
        startBLE()
    }
    
    public func startCollect() {
        onStartFlag = true
    }
    
    public func stopCollect() {
        stopCollectTimer()
        stopBLE()
        
        onStartFlag = false
    }
    
    public func getResult(completion: @escaping (Int, String) -> Void) {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        
        switch(self.service) {
        case "SD":
            let input = SectorDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postSD(url: SD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "BD":
            let input = BuildingDetection(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
            NetworkManager.shared.postBD(url: BD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "CLD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "FLD":
            let input = FineLevelDetection(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
            NetworkManager.shared.postFLD(url: FLD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "CLE":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
            NetworkManager.shared.postCLE(url: CLE_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        default:
            completion(500, "(Error) Fail to get result")
        }
    }
    
    internal func initialzeSensors() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = accX
                    sensorData.acc[0] = accX*G
                    collectData.acc[0] = accX*G
                }
                if let accY = data?.acceleration.y {
                    self.accY = accY
                    sensorData.acc[1] = accY*G
                    collectData.acc[1] = accY*G
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = accZ
                    sensorData.acc[2] = -accZ*G
                    collectData.acc[2] = -accZ*G
                }
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
                    sensorData.gyro[0] = gyroX
                    collectData.gyro[0] = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
                    sensorData.gyro[1] = gyroY
                    collectData.gyro[1] = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
                    sensorData.gyro[2] = gyroZ
                    collectData.gyro[2] = gyroZ
                }
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    self.magX = magX
                    sensorData.mag[0] = magX
                    collectData.mag[0] = magX
                }
                if let magY = data?.magneticField.y {
                    self.magY = magY
                    sensorData.mag[1] = magY
                    collectData.mag[1] = magY
                }
                if let magZ = data?.magneticField.z {
                    self.magZ = magZ
                    sensorData.mag[2] = magZ
                    collectData.mag[2] = magZ
                }
            }
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = Double(pressure)*10
                    self.pressure = pressure_
                    sensorData.pressure[0] = pressure_
                    collectData.pressure[0] = pressure_
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
                
                collectData.userAcc[0] = m.userAcceleration.x
                collectData.userAcc[1] = m.userAcceleration.y
                collectData.userAcc[2] = m.userAcceleration.z
                
                sensorData.att[0] = m.attitude.roll
                sensorData.att[1] = m.attitude.pitch
                sensorData.att[2] = m.attitude.yaw
                
                collectData.att[0] = m.attitude.roll
                collectData.att[1] = m.attitude.pitch
                collectData.att[2] = m.attitude.yaw
                
                sensorData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                sensorData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                sensorData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                                
                sensorData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                sensorData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                sensorData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                                
                sensorData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                sensorData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                sensorData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
                
                collectData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                collectData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                collectData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13
                                
                collectData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                collectData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                collectData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23
                                
                collectData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                collectData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                collectData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33
            }
        
            if let e = error {
                print(e.localizedDescription)
            }
        }
    }
    
    func startBLE() {
        bleManager.startScan(option: .Foreground)
    }

    func stopBLE() {
        bleManager.stopScan()
    }
    
    func startTimer() {
        if (receivedForceTimer == nil) {
            receivedForceTimer = Timer.scheduledTimer(timeInterval: RF_INTERVAL, target: self, selector: #selector(self.receivedForceTimerUpdate), userInfo: nil, repeats: true)
        }
        
        if (userVelocityTimer == nil && self.service == "FLT") {
            floorUpdateRequestFlag = true
            userVelocityTimer = Timer.scheduledTimer(timeInterval: UV_INTERVAL, target: self, selector: #selector(self.userVelocityTimerUpdate), userInfo: nil, repeats: true)
        }
        
        if (interruptTimer == nil && self.service == "FLT") {
            interruptTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.runInterrupt), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        if (receivedForceTimer != nil) {
            receivedForceTimer!.invalidate()
            receivedForceTimer = nil
        }
        
        if (userVelocityTimer != nil) {
            floorUpdateRequestFlag = false
            userVelocityTimer!.invalidate()
            userVelocityTimer = nil
        }
        
        if (interruptTimer != nil) {
            interruptTimer!.invalidate()
            interruptTimer = nil
        }
    }
    
    func startCollectTimer() {
        if (collectTimer == nil) {
            collectTimer = Timer.scheduledTimer(timeInterval: UV_INTERVAL, target: self, selector: #selector(self.collectTimerUpdate), userInfo: nil, repeats: true)
        }
    }
    
    func stopCollectTimer() {
        if (collectTimer != nil) {
            collectTimer!.invalidate()
            collectTimer = nil
        }
    }
    
    @objc func receivedForceTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        var bleDictionary = bleManager.bleAvg
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 mini") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: bleDictionary, pressure: self.pressure)
        
        inputReceivedForce.append(data)
        if ((inputReceivedForce.count-1) == SPATIAL_INPUT_NUM) {
            inputReceivedForce.remove(at: 0)
            NetworkManager.shared.putReceivedForce(url: RF_URL, input: inputReceivedForce)

            inputReceivedForce = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
        }
    }
    
    @objc func userVelocityTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        if (floorUpdateRequestFlag) {
            floorUpdateRequestTimer += UV_INTERVAL
            if (floorUpdateRequestTimer > FLOOR_UPDATE_REQUEST_TIME) {
                let input = FineLocationTracking(user_id: user_id, mobile_time: currentTime, sector_id: sector_id, phase: self.phase)
                
                NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                    if (statusCode == 200) {
                        let result = jsonToResult(json: returnedString)

                        self.tracking(input: result)
                    }
                })
                floorUpdateRequestTimer = 0
            }
        }
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        if (unitDRInfo.isIndexChanged) {
            displayOutput.isIndexChanged = unitDRInfo.isIndexChanged
            displayOutput.index = unitDRInfo.index
            displayOutput.length = unitDRInfo.length
            
            let data = UserVelocity(user_id: user_id, mobile_time: currentTime, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, looking: unitDRInfo.lookingFlag)
            
            // Kalman Filter
            let diffHeading = unitDRInfo.heading - preUnitHeading
            let curUnitDRLength = unitDRInfo.length
            
            // Time Update
            if (timeUpdateFlag) {
                let tuOutput = timeUpdate(length: curUnitDRLength, diffHeading: diffHeading, mobileTime: currentTime)
                self.tracking(input: tuOutput)
            }
            preUnitHeading = unitDRInfo.heading
            
            // Post FLT
            inputUserVelocity.append(data)
            if ((inputUserVelocity.count-1) == UV_INPUT_NUM) {
                inputUserVelocity.remove(at: 0)
                NetworkManager.shared.putUserVelocity(url: UV_URL, input: inputUserVelocity)
                inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                
                floorUpdateRequestFlag = true
                floorUpdateRequestTimer = 0
                
                let input = FineLocationTracking(user_id: user_id, mobile_time: currentTime, sector_id: sector_id, phase: self.phase)
                NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                    if (statusCode == 200) {
                        let result = jsonToResult(json: returnedString)
                        self.phase = result.phase
                        
                        displayOutput.level = result.level_name
                        displayOutput.scc = result.scc
                        displayOutput.phase = String(result.phase)
                        
                        // Kalman Filter
                        if (result.mobile_time > preOutputMobileTime) {
                            if (result.phase == 4) {
                                UV_INPUT_NUM = VAR_INPUT_NUM
                                if (!(result.x == 0 && result.y == 0)) {
                                    // Measurment Update
                                    if (measurementUpdateFlag) {
                                        let muOutput = measurementUpdate(timeUpdatePosition: timeUpdatePosition, serverOutput: result)
                                        self.tracking(input: muOutput)
                                    }
                                    timeUpdatePositionInit(serverOutput: result)
                                }
                            } else {
                                UV_INPUT_NUM = INIT_INPUT_NUM
                                kalmanInit()
                                self.tracking(input: result)
                            }
                            preOutputMobileTime = result.mobile_time
                        }
                    }
                })
            }
        }
    }
    
    @objc func collectTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        collectData.time = currentTime
        
        collectData.bleRaw = bleManager.bleRaw
        collectData.bleAvg = bleManager.bleAvg
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        collectData.isIndexChanged = false
        if (unitDRInfo.isIndexChanged) {
            collectData.isIndexChanged = unitDRInfo.isIndexChanged
            collectData.index = unitDRInfo.index
            collectData.length = unitDRInfo.length
            collectData.heading = unitDRInfo.heading
            collectData.lookingFlag = unitDRInfo.lookingFlag
        }
    }
    
    @objc func runInterrupt() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        let input = CoarseLevelDetection(user_id: user_id, mobile_time: currentTime)
        NetworkManager.shared.postCLD(url: CLC_URL, input: input, completion: { statusCode, returnedString in })
    }
    
    func getCurrentTimeInMilliseconds() -> Int
    {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    func jsonToResult(json: String) -> FineLocationTrackingResult {
        let result = FineLocationTrackingResult(mobile_time: 0, building_name: "", level_name: "", scc: 0, scr: 0, x: 0, y: 0, absolute_heading: 0, phase: 0, calculated_time: 0, index: 0)
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingResult.self, from: data) {
            
            return decoded
        }

        return result
    }
    
    private func parseRoad(data: String) -> ( [[Double]], [String] ) {
        var road = [[Double]]()
        var roadHeading = [String]()
        
        var roadX = [Double]()
        var roadY = [Double]()
        
        let roadString = data.components(separatedBy: .newlines)
        for i in 0..<roadString.count {
            if (roadString[i] != "") {
                let lineData = roadString[i].components(separatedBy: ",")
                
                roadX.append(Double(lineData[0])!)
                roadY.append(Double(lineData[1])!)
                
                var headingArray: String = ""
                if (lineData.count > 2) {
                    for j in 2..<lineData.count {
                        headingArray.append(lineData[j])
                        if (lineData[j] != "") {
                            headingArray.append(",")
                        }
                    }
                }
                roadHeading.append(headingArray)
            }
        }
        
        road = [roadX, roadY]
        
        return (road, roadHeading)
    }
    
    private func correct(building: String, level: String, x: Double, y: Double, heading: Double) -> [Double] {
        var xyh: [Double] = [x, y, heading]
        
        let key: String = "\(building)_\(level)"
        
        let mainRoad: [[Double]] = Road[key]!
        let mainHeading: [String] = RoadHeading[key]!

        var diffXY = [Double]()
        if (!mainRoad.isEmpty) {
            let roadX = mainRoad[0]
            let roadY = mainRoad[1]
            
            for i in 0..<roadX.count {
                diffXY.append(sqrt(pow(roadX[i] - x, 2) + pow(roadY[i] - y, 2)))
            }
            let minIdx = diffXY.firstIndex(of: diffXY.min()!)!
            var headingArray = mainHeading[minIdx]
            let headingData = headingArray.components(separatedBy: ",")
            
            var diffHeading = [Double]()
            for i in 0..<headingData.count {
                if (headingData[i] != "") {
                    let mapHeading = Double(headingData[i])!
                    diffHeading.append(abs(heading - mapHeading))
                }
            }
            let minHeadingIdx = diffHeading.firstIndex(of: diffHeading.min()!)!
            
            xyh = [roadX[minIdx], roadY[minIdx], Double(headingData[minHeadingIdx])!]
        }
        
        return xyh
    }
    
    func postUser(url: String, input: UserInfo, completion: @escaping (Int, String) -> Void) {
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { [self] response in
            switch response.result {
            case .success(let res):
                do {
                    let returnedString = String(decoding: response.data!, as: UTF8.self)
                    completion(200, returnedString)
                }
                catch (let err){
                    completion(500, "Fail")
                }
                break
            case .failure(let err):
                completion(500, "Fail")
                break
            }
        }
    }
    
    func jsonToCardList(json: String) -> CardList {
        let result = CardList(sectors: [])
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
            
            return decoded
        }
        
        return result
    }
    
    // Kalman Filter
    func kalmanInit() {
        kalmanP = 1
        kalmanQ = 0.3
        kalmanR = 3
        kalmanK = 1

        headingKalmanP = 0.5
        headingKalmanQ = 0.5
        headingKalmanR = 1
        headingKalmanK = 1

        timeUpdatePosition = KalmanOutput()
        measurementPosition = KalmanOutput()

        timeUpdateOutput = FineLocationTrackingResult()
        measurementOutput = FineLocationTrackingResult()

        timeUpdateFlag = false
        measurementUpdateFlag = false
    }

    func timeUpdatePositionInit(serverOutput: FineLocationTrackingResult) {
        timeUpdateOutput = serverOutput
        if (!measurementUpdateFlag) {
            timeUpdatePosition = KalmanOutput(x: Double(timeUpdateOutput.x), y: Double(timeUpdateOutput.y), heading: timeUpdateOutput.absolute_heading)
            timeUpdateFlag = true
        } else {
            timeUpdatePosition = KalmanOutput(x: measurementPosition.x, y: measurementPosition.y, heading: updateHeading)
        }
    }

    func timeUpdate(length: Double, diffHeading: Double, mobileTime: Int) -> FineLocationTrackingResult {

        updateHeading = timeUpdatePosition.heading + diffHeading

        timeUpdatePosition.x = timeUpdatePosition.x + (length*cos(updateHeading*D2R))
        timeUpdatePosition.y = timeUpdatePosition.y + (length*sin(updateHeading*D2R))
        timeUpdatePosition.heading = updateHeading

        kalmanP += kalmanQ
        headingKalmanP += headingKalmanQ

        timeUpdateOutput.x = timeUpdatePosition.x
        timeUpdateOutput.y = timeUpdatePosition.y
        timeUpdateOutput.mobile_time = mobileTime

        measurementUpdateFlag = true

        return timeUpdateOutput
    }

    func measurementUpdate(timeUpdatePosition: KalmanOutput, serverOutput: FineLocationTrackingResult) -> FineLocationTrackingResult {
        measurementOutput = serverOutput

        kalmanK = kalmanP / (kalmanP + kalmanR)
        headingKalmanK = headingKalmanP / (headingKalmanP + headingKalmanR)

        measurementPosition.x = timeUpdatePosition.x + kalmanK * (Double(serverOutput.x) - timeUpdatePosition.x)
        measurementPosition.y = timeUpdatePosition.y + kalmanK * (Double(serverOutput.y) - timeUpdatePosition.y)
        updateHeading = timeUpdatePosition.heading + headingKalmanK * (serverOutput.absolute_heading - timeUpdatePosition.heading)

        measurementOutput.x = measurementPosition.x
        measurementOutput.y = measurementPosition.y
        kalmanP -= kalmanK * kalmanP
        headingKalmanP -= headingKalmanK * headingKalmanP

        return measurementOutput

    }
}
