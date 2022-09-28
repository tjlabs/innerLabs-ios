import Foundation
import CoreMotion
import Alamofire

public class ServiceManager: Observation {
    
    func tracking(input: FineLocationTrackingResult) {
        for observer in observers {
            var result = input
            
            if (result.x != 0 && result.y != 0) {
                if (result.absolute_heading < 0) {
                    result.absolute_heading = result.absolute_heading + 360
                }
                result.absolute_heading = result.absolute_heading - floor(result.absolute_heading/360)*360
                
                // Map Matching
                if (self.isMapMatching) {
                    let correctResult = correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, mode: self.mode)
                    
                    if (correctResult.isSuccess) {
                        result.x = correctResult.xyh[0]
                        result.y = correctResult.xyh[1]
                        result.absolute_heading = correctResult.xyh[2]
                        
                        self.pastMatchingResult = result
                    } else {
                        result = pastMatchingResult
                    }
                }
                displayOutput.heading = result.absolute_heading
                
                // Averaging
                if (!pastResult.isEmpty) {
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
    
    var requestTimer: Timer?
    var RQ_INTERVAL: TimeInterval = 1/40 // second
    
    let SENSOR_INTERVAL: TimeInterval = 1/200
    
    var collectTimer: Timer?
    
    let CLC_INTERVAL: TimeInterval = 2
    var interruptTimer: Timer?
    // ------------------ //
    
    
    // ----- Network ----- //
    let USER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/user"
    var inputReceivedForce: [ReceivedForce] = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var inputUserVelocity: [UserVelocity] = [UserVelocity(user_id: "", mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
    
    var inputForOSA: [ReceivedForce] = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
    var isStartOSA: Bool = false
    // ------------------- //
    
    
    // ----- Fine Location Tracking ----- //
    var unitDRInfo = UnitDRInfo()
    var unitDRGenerator = UnitDRGenerator()
    
    var unitDistane: Double = 0
    var onStartFlag: Bool = false
    
    var preOutputMobileTime: Int = 0
    var preUnitHeading: Double = 0
    
    var floorUpdateRequestTimer: Double = 0
    var floorUpdateRequestFlag: Bool = true
    let FLOOR_UPDATE_REQUEST_TIME: Double = 15
    
    public var displayOutput = ServiceResult()
    
    var nowTime: Int = 0
    let RECENT_THRESHOLD: Int = 2200
    // --------------------------------- //
    
    
    // ----------- Kalman Filter ------------ //
    var phase: Int = 0
    var indexCurrent: Int = 0
    var indexPast: Int = 0
    
    var indexSend: Int = 0
    var indexReceived: Int = 0
    
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

    var timeUpdateOutput = FineLocationTrackingFromServer()
    var measurementOutput = FineLocationTrackingFromServer()
    
    var pastResult = [Double]()
    var pastBuildingLevel = ["", ""]
    
    var isMapMatching: Bool = false
    
    var isActiveService: Bool = true
    var isAnswered: Bool = false
    
    var timeActiveRF: Double = 0
    var timeActiveUV: Double = 0
    var timeUpdateInSleep: Double = 0
    let SLEEP_THRESHOLD: Double = 600 // 10분
    
    let SQUARE_RANGE: Double = 10
    var pastMatchingResult = FineLocationTrackingResult()
    
    
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
                INIT_INPUT_NUM = 2
                VAR_INPUT_NUM = 5
            } else if (mode == "dr") {
                INIT_INPUT_NUM = 5
                VAR_INPUT_NUM = 5
            }
            UV_INPUT_NUM = INIT_INPUT_NUM
            
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
        case "OSA":
            numInput = 6
            interval = 1/5
        default:
            print("(Error) Fail to initialize the service")
        }
        
        self.SPATIAL_INPUT_NUM = numInput
        self.RF_INTERVAL = interval
        
        self.initService()
        
        if (self.user_id.isEmpty || self.user_id.contains(" ")) {
            print("(Jupiter) User ID cannot be empty or contain space")
        } else {
            let userInfo = UserInfo(user_id: self.user_id, device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: userInfo, completion: { statusCode, returnedString in })
            
            let adminInfo = UserInfo(user_id: "tjlabsAdmin", device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: adminInfo, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    let list = jsonToCardList(json: returnedString)
                    let myCard = list.sectors

                    for card in 0..<myCard.count {
                        let cardInfo: CardInfo = myCard[card]
                        let id: Int = cardInfo.sector_id

                        if (id == self.sector_id) {
                            self.isMapMatching = true
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

                                    let url = "https://storage.googleapis.com/jupiter_image/pp/\(self.sector_id)/\(key).csv"
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
            print("(Jupiter) Start Service")
        }
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
            let input = BuildingDetection(user_id: self.user_id, mobile_time: currentTime)
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
        case "OSA":
            print("OSA Result")
        default:
            completion(500, "Unvalid Service Name")
        }
    }
    
    internal func initialzeSensors() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = -accX
                    sensorData.acc[0] = -accX*G
                    collectData.acc[0] = -accX*G
                }
                if let accY = data?.acceleration.y {
                    self.accY = -accY
                    sensorData.acc[1] = -accY*G
                    collectData.acc[1] = -accY*G
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = -accZ
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
                
                collectData.quaternion[0] = m.attitude.quaternion.x
                collectData.quaternion[1] = m.attitude.quaternion.y
                collectData.quaternion[2] = m.attitude.quaternion.z
                collectData.quaternion[3] = m.attitude.quaternion.w
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
            if (self.service == "OSA") {
                receivedForceTimer = Timer.scheduledTimer(timeInterval: RF_INTERVAL, target: self, selector: #selector(self.osaTimerUpdate), userInfo: nil, repeats: true)
            } else {
                receivedForceTimer = Timer.scheduledTimer(timeInterval: RF_INTERVAL, target: self, selector: #selector(self.receivedForceTimerUpdate), userInfo: nil, repeats: true)
            }
        }
        
        if (userVelocityTimer == nil && self.service == "FLT") {
            floorUpdateRequestFlag = true
            userVelocityTimer = Timer.scheduledTimer(timeInterval: UV_INTERVAL, target: self, selector: #selector(self.userVelocityTimerUpdate), userInfo: nil, repeats: true)
        }
        
        if (requestTimer == nil && self.service == "FLT") {
            requestTimer = Timer.scheduledTimer(timeInterval: RQ_INTERVAL, target: self, selector: #selector(self.requestTimerUpdate), userInfo: nil, repeats: true)
        }

        if (interruptTimer == nil && self.service == "FLT") {
            interruptTimer = Timer.scheduledTimer(timeInterval: CLC_INTERVAL, target: self, selector: #selector(self.runInterrupt), userInfo: nil, repeats: true)
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
        
        if (requestTimer != nil) {
            requestTimer!.invalidate()
            requestTimer = nil
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
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 Mini") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        if (!bleDictionary.isEmpty) {
            timeActiveRF = 0
            isActiveService = true
            
            if (isActiveService) {
                let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: bleDictionary, pressure: self.pressure)
                
                inputReceivedForce.append(data)
                if ((inputReceivedForce.count-1) == SPATIAL_INPUT_NUM) {
                    inputReceivedForce.remove(at: 0)
                    NetworkManager.shared.putReceivedForce(url: RF_URL, input: inputReceivedForce)

                    inputReceivedForce = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
                }
            }
        } else {
            timeActiveRF += RF_INTERVAL
            if (timeActiveRF >= SLEEP_THRESHOLD) {
                isActiveService = false
                timeActiveRF = 0
            }
        }
    }
    
    @objc func userVelocityTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        if (floorUpdateRequestFlag && isActiveService) {
            floorUpdateRequestTimer += UV_INTERVAL
            if (floorUpdateRequestTimer > FLOOR_UPDATE_REQUEST_TIME) {
                let input = FineLocationTracking(user_id: user_id, mobile_time: currentTime, sector_id: sector_id, phase: self.phase)
                
                NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                    if (statusCode == 200) {
                        let result = jsonToResult(json: returnedString)
                        let finalResult = fromServerToResult(fromServer: result, velocity: displayOutput.velocity)
                        print("(Tracking) Floor Changed")
                        self.tracking(input: finalResult)
                    }
                })
                floorUpdateRequestTimer = 0
            }
        }
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        if (unitDRInfo.isIndexChanged) {
            timeActiveUV = 0
            isActiveService = true
            
            displayOutput.isIndexChanged = unitDRInfo.isIndexChanged
            displayOutput.indexTx = unitDRInfo.index
            displayOutput.length = unitDRInfo.length
            displayOutput.velocity = unitDRInfo.velocity * 3.6
            
            let data = UserVelocity(user_id: user_id, mobile_time: currentTime, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, looking: unitDRInfo.lookingFlag)
            
            // Kalman Filter
            let diffHeading = unitDRInfo.heading - preUnitHeading
            let curUnitDRLength = unitDRInfo.length
            
            if (isActiveService) {
                inputUserVelocity.append(data)
                
                // Time Update
                if (timeUpdateFlag) {
                    let tuOutput = timeUpdate(length: curUnitDRLength, diffHeading: diffHeading, mobileTime: currentTime)
                    let tuResult = fromServerToResult(fromServer: tuOutput, velocity: displayOutput.velocity)
                    self.tracking(input: tuResult)
                }
                preUnitHeading = unitDRInfo.heading
                
                // Put UV
                if ((inputUserVelocity.count-1) >= UV_INPUT_NUM) {
                    inputUserVelocity.remove(at: 0)
                    NetworkManager.shared.putUserVelocity(url: UV_URL, input: inputUserVelocity, completion: { [self] statusCode, returnedString in
                        if (statusCode == 200) {
                            floorUpdateRequestFlag = true
                            floorUpdateRequestTimer = 0
                            
                            indexSend = Int(returnedString) ?? 0
                            isAnswered = true
                        }
                    })
                    inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                }
            }
        } else {
            // UV가 발생하지 않음
            timeActiveUV += UV_INTERVAL
            if (timeActiveUV >= SLEEP_THRESHOLD) {
                print("Enter Sleep Mode")
                isActiveService = false
                timeActiveUV = 0
            }
        }
    }
    
    @objc func requestTimerUpdate() {
        if (self.isAnswered) {
            self.isAnswered = false
            
            // Request FLT
            let currentTime = getCurrentTimeInMilliseconds()
            nowTime = currentTime

            let input = FineLocationTracking(user_id: user_id, mobile_time: currentTime, sector_id: sector_id, phase: self.phase)
            NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    let result = jsonToResult(json: returnedString)
                    
                    if ((self.nowTime - result.mobile_time) <= RECENT_THRESHOLD) {
                        self.phase = result.phase

                        displayOutput.building = result.building_name
                        displayOutput.level = result.level_name
                        
                        if ((result.index - indexPast) < 10) {
                            displayOutput.scc = result.scc
                            displayOutput.phase = String(result.phase)
                            displayOutput.indexRx = result.index

                            // Kalman Filter
                            if (result.mobile_time > preOutputMobileTime) {
                                if (result.phase == 4) {
                                    UV_INPUT_NUM = VAR_INPUT_NUM
                                    if (!(result.x == 0 && result.y == 0)) {
                                        // Measurment Update
                                        let diffIndex = abs(indexSend - result.index)
                                        if (measurementUpdateFlag && (diffIndex<2)) {
                                            let muOutput = measurementUpdate(timeUpdatePosition: timeUpdatePosition, serverOutput: result)
                                            let muResult = fromServerToResult(fromServer: muOutput, velocity: displayOutput.velocity)
                                            self.tracking(input: muResult)
                                        }
                                        timeUpdatePositionInit(serverOutput: result)
                                    }
                                } else {
                                    UV_INPUT_NUM = INIT_INPUT_NUM
                                    kalmanInit()
                                    let finalResult = fromServerToResult(fromServer: result, velocity: displayOutput.velocity)
                                    self.tracking(input: finalResult)
                                }
                                preOutputMobileTime = result.mobile_time
                            }
                            pastBuildingLevel = [displayOutput.building, displayOutput.level]
                        }
                        indexPast = result.index
                    }
                }
            })
        }
    }
    
    @objc func osaTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        var bleDictionary = bleManager.bleAvg
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 Mini") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        if (!bleDictionary.isEmpty) {
            let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: bleDictionary, pressure: self.pressure)
            
            inputForOSA.append(data)
            if (inputForOSA[0].user_id == "") {
                inputForOSA.remove(at: 0)
            }
        }
        
        if (inputForOSA.count == 3) {
            inputForOSA.remove(at: 0)
        }
//        print(inputForOSA)
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
    
    func jsonToResult(json: String) -> FineLocationTrackingFromServer {
        let result = FineLocationTrackingFromServer()
        let decoder = JSONDecoder()
        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingFromServer.self, from: data) {
            return decoded
        }

        return result
    }
    
    func fromServerToResult(fromServer: FineLocationTrackingFromServer, velocity: Double) -> FineLocationTrackingResult {
        var result = FineLocationTrackingResult()
        
        result.mobile_time = fromServer.mobile_time
        result.building_name = fromServer.building_name
        result.level_name = fromServer.level_name
        result.scc = fromServer.scc
        result.scr = fromServer.scr
        result.x = fromServer.x
        result.y = fromServer.y
        result.absolute_heading = fromServer.absolute_heading
        result.phase = fromServer.phase
        result.calculated_time = fromServer.calculated_time
        result.index = fromServer.index
        result.velocity = velocity
        
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
    
    private func correct(building: String, level: String, x: Double, y: Double, heading: Double, mode: String) -> (isSuccess: Bool, xyh: [Double]) {
        var isSuccess: Bool = false
        var xyh: [Double] = [x, y, heading]
        let key: String = "\(building)_\(level)"
        
        if (!(building.isEmpty) && !(level.isEmpty)) {
            guard let mainRoad: [[Double]] = Road[key] else {
                return (isSuccess, xyh)
            }
            guard let mainHeading: [String] = RoadHeading[key] else {
                return (isSuccess, xyh)
            }
            
            // Heading 사용
            var idhArray = [[Double]]()
            var pathArray = [[Double]]()
            if (!mainRoad.isEmpty) {
                let roadX = mainRoad[0]
                let roadY = mainRoad[1]
                
                let xMin = x - SQUARE_RANGE
                let xMax = x + SQUARE_RANGE
                let yMin = y - SQUARE_RANGE
                let yMax = y + SQUARE_RANGE

                for i in 0..<roadX.count {
                    let xPath = roadX[i]
                    let yPath = roadY[i]

                    // XY 범위 안에 있는 값 중에 검사
                    if (xPath >= xMin && xPath <= xMax) {
                        if (yPath >= yMin && yPath <= yMax) {
                            let index = Double(i)
                            let distance = sqrt(pow(x-xPath, 2) + pow(y-yPath, 2))
                            var idh: [Double] = [index, distance, heading]
                            var path: [Double] = [xPath, yPath, 0, 0]
                            
                            let headingArray = mainHeading[i]
                            if (!headingArray.isEmpty) {
                                let headingData = headingArray.components(separatedBy: ",")
                                var diffHeading = [Double]()
                                for j in 0..<headingData.count {
                                    if(!headingData[j].isEmpty) {
                                        let mapHeading = Double(headingData[j])!
                                        if (heading > 315 && mapHeading == 0) {
                                            diffHeading.append(abs(heading - 360))
                                        } else {
                                            diffHeading.append(abs(heading - mapHeading))
                                        }
                                    }
                                }
                                
                                if (!diffHeading.isEmpty) {
                                    let idxHeading = diffHeading.firstIndex(of: diffHeading.min()!)
                                    let minHeading = Double(headingData[idxHeading!])!
                                    idh[2] = minHeading
                                    
                                    path[2] = minHeading
                                    path[3] = 1
                                }
                            }
                            idhArray.append(idh)
                            pathArray.append(path)
                        }
                    }
                }
                

                if (!idhArray.isEmpty) {
                    let sortedIdh = idhArray.sorted(by: {$0[1] < $1[1] })
                    var index: Int = 0
                    var correctedHeading: Double = heading
                    
                    if (!sortedIdh.isEmpty) {
                        let minData: [Double] = sortedIdh[0]
                        index = Int(minData[0])
                        if (mode == "dr") {
                            correctedHeading = minData[2]
                        } else {
                            correctedHeading = heading
                        }
                    }
                    isSuccess = true
                    xyh = [roadX[index], roadY[index], correctedHeading]
                }
            }
        }
        return (isSuccess, xyh)
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

        timeUpdateOutput = FineLocationTrackingFromServer()
        measurementOutput = FineLocationTrackingFromServer()

        timeUpdateFlag = false
        measurementUpdateFlag = false
    }

    func timeUpdatePositionInit(serverOutput: FineLocationTrackingFromServer) {
        timeUpdateOutput = serverOutput
        if (!measurementUpdateFlag) {
            timeUpdatePosition = KalmanOutput(x: Double(timeUpdateOutput.x), y: Double(timeUpdateOutput.y), heading: timeUpdateOutput.absolute_heading)
            timeUpdateFlag = true
        } else {
            timeUpdatePosition = KalmanOutput(x: measurementPosition.x, y: measurementPosition.y, heading: updateHeading)
        }
    }

    func timeUpdate(length: Double, diffHeading: Double, mobileTime: Int) -> FineLocationTrackingFromServer {
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

    func measurementUpdate(timeUpdatePosition: KalmanOutput, serverOutput: FineLocationTrackingFromServer) -> FineLocationTrackingFromServer {
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
