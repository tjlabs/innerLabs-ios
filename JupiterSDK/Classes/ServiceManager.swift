import Foundation
import CoreMotion

public class ServiceManager: Observation {
    
    func tracking(input: FineLocationTrackingResult, isPast: Bool) {
        for observer in observers {
            var result = input
            
            if (result.x != 0 && result.y != 0) {
                if (result.absolute_heading < 0) {
                    result.absolute_heading = result.absolute_heading + 360
                }
                result.absolute_heading = result.absolute_heading - floor(result.absolute_heading/360)*360

                // Map Matching
                if (self.isMapMatching) {
                    let correctResult = correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, mode: self.mode, isPast: isPast)
                    
                    if (correctResult.isSuccess) {
                        result.x = correctResult.xyh[0]
                        result.y = correctResult.xyh[1]
                        result.absolute_heading = correctResult.xyh[2]

                        self.pastMatchingResult = result
                        self.matchingFailCount = 0
                    } else {
                        self.matchingFailCount += 1
                        result = self.pastMatchingResult
                    }
                }
                // Averaging
                if (!pastResult.isEmpty) {
                    if (pastResult[2] >= 270 && pastResult[2] <= 360) && (result.absolute_heading >= 0 && result.absolute_heading <= 90) {
                        result.absolute_heading = ((result.absolute_heading+360) + pastResult[2])/2
                    } else if (pastResult[2] >= 0 && pastResult[2] <= 90) && (result.absolute_heading >= 270 && result.absolute_heading <= 360) {
                        result.absolute_heading = (result.absolute_heading + (pastResult[2]+360))/2
                    } else {
                        result.absolute_heading = (result.absolute_heading + pastResult[2])/2
                    }
                    result.absolute_heading = result.absolute_heading - floor(result.absolute_heading/360)*360
                }
                
                displayOutput.heading = result.absolute_heading

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

                var updatedResult = FineLocationTrackingResult()
                updatedResult.mobile_time = getCurrentTimeInMilliseconds()
                updatedResult.building_name = result.building_name
                updatedResult.level_name = result.level_name
                updatedResult.scc = result.scc
                updatedResult.scr = result.scr
                updatedResult.x = result.x
                updatedResult.y = result.y
                updatedResult.absolute_heading = result.absolute_heading
                updatedResult.phase = result.phase
                updatedResult.calculated_time = result.calculated_time
                updatedResult.index = result.index
                updatedResult.velocity = result.velocity

                self.lastTrackingTime = updatedResult.mobile_time
                self.lastResult = updatedResult
                
                do {
                    let key: String = "JupiterLastResult_\(self.sector_id)"
                    let jsonData = try JSONEncoder().encode(self.lastResult)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    UserDefaults.standard.set(jsonString, forKey: key)
                } catch {
                    print("(Jupiter) Error : Fail to save last result")
                }
                
                observer.update(result: updatedResult)
            } else {
                var updatedResult = FineLocationTrackingResult()
                updatedResult.mobile_time = getCurrentTimeInMilliseconds()
                updatedResult.building_name = result.building_name
                updatedResult.level_name = result.level_name
                updatedResult.scc = result.scc
                updatedResult.scr = result.scr
                updatedResult.x = result.x
                updatedResult.y = result.y
                updatedResult.absolute_heading = result.absolute_heading
                updatedResult.phase = result.phase
                updatedResult.calculated_time = result.calculated_time
                updatedResult.index = result.index
                updatedResult.velocity = result.velocity
                
                do {
                    let key: String = "JupiterLastResult_\(self.sector_id)"
                    let jsonData = try JSONEncoder().encode(self.lastResult)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    UserDefaults.standard.set(jsonString, forKey: key)
                } catch {
                    print("(Jupiter) Warning : Fail to save last result")
                }

                self.lastTrackingTime = updatedResult.mobile_time
                self.lastResult = updatedResult
            }
            // For COEX B1
//            if (result.building_name == "COEX" && result.level_name == "B1") {
//
//                result.x = 200
//                result.y = 207
//                result.absolute_heading = 0
//            }
        }
    }
    
    // 0 : Release  //  1 : Test
    var serverType: Int = 0
    // 0 : Android  //  1 : iOS
    var osType: Int = 1
    
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
    var isStartOSA: Bool = false
    // ------------------- //
    
    
    // ----- Fine Location Tracking ----- //
    var unitDRInfo = UnitDRInfo()
    var unitDRGenerator = UnitDRGenerator()
    
    var unitDistane: Double = 0
    var onStartFlag: Bool = false
    
    var preOutputMobileTime: Int = 0
    var preUnitHeading: Double = 0
    
    var floorUpdateRequestTimeStack: Double = 0
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
    var isActiveRF: Bool = true
    var isAnswered: Bool = false
    var isFirstStart: Bool = true
    var isStop: Bool = false
    
    var timeActiveRF: Double = 0
    var timeActiveUV: Double = 0
    var timeInitUV: Double = 0
    var timeUpdateInSleep: Double = 0
    let STOP_THRESHOLD: Double = 1 // 0.5 sec
    let SLEEP_THRESHOLD: Double = 600 // 10분
    let SLEEP_THRESHOLD_RF: Double = 5 // 5s
    let INIT_HRESHOLD: Double = 10 // 10s
    
    var lastTrackingTime: Int = 0
    var lastResult = FineLocationTrackingResult()
    let SQUARE_RANGE: Double = 10
    var pastMatchingResult = FineLocationTrackingResult()
    var matchingFailCount: Int = 0
    let MATCHING_FAIL_THRESHOLD: Int = 5
    
    var isPastServerResult: Bool = false
    let COORD_THRESHOLD: Double = 20
    
    var pastUVTime = 0
    var pastRQTime = 0
    
    // File for write Errors
    let fileManager = FileManager.default
    var textFile: URL?
    var errorLogs: String = ""
    let flagSaveError: Bool = true
    
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
        
        isFirstStart = true
        onStartFlag = false
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
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
        
        // File
        if (flagSaveError) {
            print("(Jupiter) Process : Creating error log file")
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("Jupiter")
            let localTime: String = getLocalTimeString()
            if !fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.createDirectory(atPath: fileURL.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("(Jupiter) Error : Cannot create Jupiter")
                }
            } else {
                let textPath: URL = fileURL.appendingPathComponent("logs_\(localTime).txt")
                self.textFile = textPath
            }
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
        case "CLD":
            numInput = 3
            interval = 1/2
        case "CLE":
            numInput = 7
            interval = 1/2
        case "FLT":
            numInput = 6
            interval = 1/5
        case "OSA":
            numInput = 3
            interval = 1/5
        default:
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize the service\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        self.SPATIAL_INPUT_NUM = numInput
        self.RF_INTERVAL = interval
        
        self.initService()
        
        if (self.user_id.isEmpty || self.user_id.contains(" ")) {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : User ID cannot be empty or contain space\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        } else {
            let userInfo = UserInfo(user_id: self.user_id, device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: userInfo, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    settingURL(server: self.serverType, os: self.osType)
                } else {
                    let localTime: String = getLocalTimeString()
                    let log: String = localTime + " , (Jupiter) Error : Load OS Type Error\n"
                    if (flagSaveError) {
                        self.errorLogs.append(log)
                    } else {
                       print(log)
                    }
                }
            })
            
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
                                    // [http 비동기 방식을 사용해서 http 요청 수행 실시]
                                    let urlComponents = URLComponents(string: url)
                                    let requestURL = URLRequest(url: (urlComponents?.url)!)
                                    let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

                                        if (statusCode == 200) {
                                            if let responseData = data {
                                                if let utf8Text = String(data: responseData, encoding: .utf8) {
                                                    ( self.Road[key], self.RoadHeading[key] ) = self.parseRoad(data: utf8Text)
                                                }
                                            }
                                        }
                                    })
                                    dataTask.resume()
                                }
                            }
                        }
                    }
                }
            })
            print("(Jupiter) Start Service")
        }
    }
    
    func settingURL(server: Int, os: Int) {
        // (server) 0 : Release  //  1 : Test
        // (os) 0 : Android  //  1 : iOS
        
        if (server == 0 && os == 0) {
            BASE_URL = RELEASE_URL_A
        } else if (server == 0 && os == 1) {
            BASE_URL = RELEASE_URL_i
        } else if (server == 1 && os == 0) {
            BASE_URL = TEST_URL_A
        } else if (server == 1 && os == 1) {
            BASE_URL = TEST_URL_i
        } else {
            BASE_URL = RELEASE_URL_i
        }
    }
    
    public func stopService() {
        stopTimer()
        stopBLE()
        
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
            onStartFlag = false
        }
        
        if (flagSaveError) {
            saveErrorFile(log: self.errorLogs)
        }
        
        print("(Jupiter) Stop Service")
        isFirstStart = true
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
        case "CLD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "CLE":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
            NetworkManager.shared.postCLE(url: CLE_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "OSA":
            let input = OnSpotAuthorization(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postOSA(url: OSA_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        default:
            completion(500, "(Jupiter) Error : Unvalid Service Name")
        }
    }
    
    internal func initialzeSensors() {
        var sensorActive: Int = 0
        if motionManager.isAccelerometerAvailable {
            sensorActive += 1
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
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize accelerometer\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        if motionManager.isGyroAvailable {
            sensorActive += 1
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
//                    sensorData.gyro[0] = gyroX
//                    collectData.gyro[0] = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
//                    sensorData.gyro[1] = gyroY
//                    collectData.gyro[1] = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
//                    sensorData.gyro[2] = gyroZ
//                    collectData.gyro[2] = gyroZ
                }
//                print("Raw : \(sensorData.gyro[0]), \(sensorData.gyro[1]), \(sensorData.gyro[2])")
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize gyroscope\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            sensorActive += 1
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
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize magnetometer\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            sensorActive += 1
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = Double(pressure)*10
                    self.pressure = pressure_
                    sensorData.pressure[0] = pressure_
                    collectData.pressure[0] = pressure_
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize pressure sensor\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
            sensorActive += 1
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
                    
//                    print("Cal : \(m.rotationRate.x), \(m.rotationRate.y), \(m.rotationRate.z)")
                    sensorData.gyro[0] = m.rotationRate.x
                    sensorData.gyro[1] = m.rotationRate.y
                    sensorData.gyro[2] = m.rotationRate.z
                    collectData.gyro[0] = m.rotationRate.x
                    collectData.gyro[1] = m.rotationRate.y
                    collectData.gyro[2] = m.rotationRate.z
                    
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
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize motion sensor\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        if (sensorActive >= 5) {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Success : initialize sensors\n"
            if (flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
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
        
        if (requestTimer == nil && self.service == "FLT") {
            requestTimer = Timer.scheduledTimer(timeInterval: RQ_INTERVAL, target: self, selector: #selector(self.requestTimerUpdate), userInfo: nil, repeats: true)
        }

//        if (interruptTimer == nil && self.service == "FLT") {
//            interruptTimer = Timer.scheduledTimer(timeInterval: CLC_INTERVAL, target: self, selector: #selector(self.runInterrupt), userInfo: nil, repeats: true)
//        }
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
        
        bleManager.trimBleData()
        
        var bleDictionary = bleManager.bleAvg
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 Mini" || deviceModel == "iPhone X") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
    
        let bleCheckTime = Double(currentTime)
        let discoveredTime = bleManager.bleDiscoveredTime
        let diffBleTime = (bleCheckTime - discoveredTime)*1e-3
        let localTime: String = getLocalTimeString()
        let log: String = localTime + "__(Jupiter) BLE Check__\(diffBleTime)__\(bleCheckTime)__\(discoveredTime)__\(bleManager.bleCheck)\n"
        if (flagSaveError) {
            self.errorLogs.append(log)
        } else {
           print(log)
        }
        
        if (!bleDictionary.isEmpty) {
            self.timeActiveRF = 0
            self.isActiveService = true
            self.isActiveRF = true
            
            if (self.isActiveService) {
                let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: bleDictionary, pressure: self.pressure)
                
                inputReceivedForce.append(data)
                if ((inputReceivedForce.count-1) == SPATIAL_INPUT_NUM) {
                    inputReceivedForce.remove(at: 0)
                    NetworkManager.shared.putReceivedForce(url: RF_URL, input: inputReceivedForce, completion: { [self] statusCode, returnedStrig in
                        if (statusCode != 200) {
                            let localTime: String = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Error : Fail to send BLE\n"
                            if (flagSaveError) {
                                self.errorLogs.append(log)
                            } else {
                               print(log)
                            }
                        }
                    })
                    inputReceivedForce = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
                }
            }
        } else {
            print("(Jupiter) RF is Empty")
            self.timeActiveRF += RF_INTERVAL
            if (self.timeActiveRF >= SLEEP_THRESHOLD_RF) {
//                print("(Jupiter) RF is Empty")
                self.isActiveService = false
                self.isActiveRF = false
                self.timeActiveRF = 0
            }
        }
    }
    
    @objc func userVelocityTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
        }
        
        if (unitDRInfo.isIndexChanged) {
            self.timeActiveUV = 0
            self.timeInitUV = 0
            self.isActiveService = true
            self.isStop = false
            
            displayOutput.isIndexChanged = unitDRInfo.isIndexChanged
            displayOutput.indexTx = unitDRInfo.index
            displayOutput.length = unitDRInfo.length
            displayOutput.velocity = unitDRInfo.velocity * 3.6
            
            let data = UserVelocity(user_id: self.user_id, mobile_time: currentTime, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, looking: unitDRInfo.lookingFlag)
            
            // Kalman Filter
            let diffHeading = unitDRInfo.heading - preUnitHeading
            let curUnitDRLength = unitDRInfo.length
            
            if (self.isActiveService) {
                inputUserVelocity.append(data)
                
                // Time Update
                if (timeUpdateFlag) {
                    let tuOutput = timeUpdate(length: curUnitDRLength, diffHeading: diffHeading, mobileTime: currentTime)
                    let tuResult = fromServerToResult(fromServer: tuOutput, velocity: displayOutput.velocity)
                    self.tracking(input: tuResult, isPast: false)
                }
                preUnitHeading = unitDRInfo.heading
                
                // Put UV
                if ((inputUserVelocity.count-1) >= UV_INPUT_NUM) {
                    inputUserVelocity.remove(at: 0)

                    NetworkManager.shared.putUserVelocity(url: UV_URL, input: inputUserVelocity, completion: { [self] statusCode, returnedString in
                        if (statusCode == 200) {
                            floorUpdateRequestFlag = true
                            floorUpdateRequestTimeStack = 0
                            
                            indexSend = Int(returnedString) ?? 0
                            isAnswered = true
                        } else {
                            let localTime: String = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Error : Fail to send sensor measurements\n"
                            if (flagSaveError) {
                                self.errorLogs.append(log)
                                print(self.errorLogs)
                            } else {
                               print(log)
                            }
                        }
                    })
                    inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                }
            }
        } else {
            // UV가 발생하지 않음
            timeActiveUV += UV_INTERVAL
            if (timeActiveUV >= STOP_THRESHOLD) {
                self.isStop = true
                timeActiveUV = 0
                displayOutput.velocity = 0
            }
            
            self.timeInitUV += UV_INTERVAL
            if (self.timeInitUV >= INIT_HRESHOLD) {
                self.phase = 1
                self.timeInitUV = 0
            }
            
            if (timeActiveUV >= SLEEP_THRESHOLD) {
                print("(Jupiter) Enter Sleep Mode")
                self.isActiveService = false
                timeActiveUV = 0
            }
        }
    }
    
    @objc func requestTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        if (self.isAnswered && self.isActiveRF) {
            self.isAnswered = false

            // Request FLT
            nowTime = currentTime
            let input = FineLocationTracking(user_id: user_id, mobile_time: currentTime, sector_id: sector_id, phase: self.phase)
            NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    var result = jsonToResult(json: returnedString)
                    
                    if ((self.nowTime - result.mobile_time) <= RECENT_THRESHOLD) {
                        self.phase = result.phase

                        displayOutput.building = result.building_name
                        displayOutput.level = result.level_name
                        
                        if ((result.index - indexPast) < 6) {
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
                                        if (measurementUpdateFlag && (diffIndex<1)) {
                                            let muOutput = measurementUpdate(timeUpdatePosition: timeUpdatePosition, serverOutput: result)
                                            let muResult = fromServerToResult(fromServer: muOutput, velocity: displayOutput.velocity)
                                            
                                            self.tracking(input: muResult, isPast: false)
                                        }
                                        timeUpdatePositionInit(serverOutput: result)
                                    }
                                } else {
                                    UV_INPUT_NUM = INIT_INPUT_NUM
                                    kalmanInit()
                                    let finalResult = fromServerToResult(fromServer: result, velocity: displayOutput.velocity)
                                    self.tracking(input: finalResult, isPast: false)
                                }
                                preOutputMobileTime = result.mobile_time
                                isPastServerResult = true
                            }
                            pastBuildingLevel = [displayOutput.building, displayOutput.level]
                        }
                        indexPast = result.index
                    }
                }
            })
        } else {
            let diffUpdatedTime: Int = currentTime - self.lastTrackingTime
            if (diffUpdatedTime > 950) {
                if (self.lastTrackingTime != 0 && self.isActiveRF) {
//                    print("(Jupiter) Past Result")
                    self.tracking(input: self.lastResult, isPast: true)
                } else {
                    if (isFirstStart) {
                        let key: String = "JupiterLastResult_\(self.sector_id)"
                        if let lastKnownResult: String = UserDefaults.standard.object(forKey: key) as? String {
//                            print("(Jupiter) Success : Load Last Known Result")
                            let currentTime = getCurrentTimeInMilliseconds()
                            let result = jsonForTracking(json: lastKnownResult)
                            if (currentTime - result.mobile_time) < 1000*3600*12 {
//                                var updatedResult = result
//                                updatedResult.absolute_heading = updatedResult.absolute_heading + 180
//                                print("(Jupiter) Success : \(updatedResult)")
                                self.tracking(input: result, isPast: false)
                            }
                        } else {
                            let localTime: String = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Warnings : Empty Last Result\n"
                            if (flagSaveError) {
                                self.errorLogs.append(log)
                            } else {
                               print(log)
                            }
                        }
                        isFirstStart = false
                    }
                }
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
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
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
    
    func jsonForTracking(json: String) -> FineLocationTrackingResult {
        let result = FineLocationTrackingResult()
        let decoder = JSONDecoder()
        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingResult.self, from: data) {
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
    
    private func correct(building: String, level: String, x: Double, y: Double, heading: Double, mode: String, isPast :Bool) -> (isSuccess: Bool, xyh: [Double]) {
        var isSuccess: Bool = false
        var xyh: [Double] = [x, y, heading]
        let key: String = "\(building)_\(level)"
        
        if (isPast) {
            isSuccess = true
            return (isSuccess, xyh)
        }
        
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
                            var isValidIdh: Bool = true
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
                                    if (heading > 315 && minHeading == 0) {
                                        if (abs(heading-360) >= 60) {
                                            isValidIdh = false
                                        }
                                    } else {
                                        if (abs(heading-minHeading) >= 60) {
                                            isValidIdh = false
                                        }
                                    }
                                    
                                    path[2] = minHeading
                                    path[3] = 1
                                }
                            }
                            if (isValidIdh) {
                                idhArray.append(idh)
                                pathArray.append(path)
                            }
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
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
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
    
    func saveErrorFile(log: String) {
        print("(Jupiter) Process : Saving error log file....")
        if let data: Data = log.data(using: String.Encoding.utf8) {
            do {
                guard let errorFile = self.textFile else {
                    print("(Jupiter) Error : Fail to save error logs")
                    return
                }
                print("(Jupiter) Process : Error logs")
                print(data)
                try data.write(to: errorFile)
            } catch let e {
                print(e.localizedDescription)
            }
        }
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
//        print("(Heading) MU : \(timeUpdatePosition.heading) , \(measurementOutput.absolute_heading), \(timeUpdatePosition.heading - measurementOutput.absolute_heading)")

        return measurementOutput
    }
}
