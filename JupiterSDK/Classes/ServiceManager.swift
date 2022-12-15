import Foundation
import CoreMotion

public class ServiceManager: Observation {
    
    func tracking(input: FineLocationTrackingResult, isPast: Bool) {
        for observer in observers {
            var result = input
            
            if (result.x != 0 && result.y != 0) {
                result.absolute_heading = compensateHeading(heading: result.absolute_heading, mode: self.mode)
                
                let beforeX = result.x
                let beforeY = result.y
                let beforeHeading = result.absolute_heading
                
                // Map Matching
                if (self.isMapMatching) {
                    let correctResult = correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], isMu: false, mode: self.mode, isPast: isPast, HEADING_RANGE: self.HEADING_RANGE)

                    if (correctResult.isSuccess) {
                        result.x = correctResult.xyh[0]
                        result.y = correctResult.xyh[1]
                        result.absolute_heading = correctResult.xyh[2]
                    } else if (isActiveKf) {
                        result = self.lastResult
                    }
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
                let trackingTime = getCurrentTimeInMilliseconds()
                self.lastTrackingTime = trackingTime
                
                updatedResult.mobile_time = trackingTime
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
                
                displayOutput.building = updatedResult.building_name
                displayOutput.level = self.removeLevelDirectionString(levelName: updatedResult.level_name)
//                displayOutput.level = updatedResult.level_name
                
                displayOutput.scc = updatedResult.scc
                displayOutput.phase = String(updatedResult.phase)

                self.lastResult = updatedResult
                
                self.pastBuildingLevel = [updatedResult.building_name, updatedResult.level_name]
                
                do {
                    let key: String = "JupiterLastResult_\(self.sector_id)"
                    let jsonData = try JSONEncoder().encode(self.lastResult)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    UserDefaults.standard.set(jsonString, forKey: key)
                } catch {
                    print("(Jupiter) Error : Fail to save last result")
                }
                
                if (self.flagSaveBle) {
                    let localTime: String = getLocalTimeString()
                    let log: String = localTime + "__(Jupiter) Result Check__\(updatedResult.mobile_time)__\(updatedResult.building_name)__\(updatedResult.level_name)__\(updatedResult.scc)__\(updatedResult.x)__\(updatedResult.y)__\(updatedResult.absolute_heading)__\(updatedResult.phase)__\(updatedResult.calculated_time)__\(updatedResult.index)__\(updatedResult.velocity)__\(beforeX)__\(beforeY)__\(beforeHeading)__\(self.muTime)__\(self.muIndex)__\(self.muX)__\(self.muY)__\(self.muHeading)\n"
                    self.errorLogs.append(log)
                }
                
                observer.update(result: updatedResult)
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
    var serverType: Int = 1
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
    
    var gyroRawX: Double = 0
    var gyroRawY: Double = 0
    var gyroRawZ: Double = 0
    
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
    
    var updateTimer: Timer?
    var UPDATE_INTERVAL: TimeInterval = 1/5 // second
    
    var osrTimer: Timer?
    var OSR_INTERVAL: TimeInterval = 2
    
    let SENSOR_INTERVAL: TimeInterval = 1/100
    
    var collectTimer: Timer?
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
    var RECENT_THRESHOLD: Int = 10000 // 2200
    var INDEX_THRESHOLD: Int = 6
    
    var lastOsrId: Int = 0
    var lastOsrTime: Int = 0
    var travelingOsrDistance: Double = 0
    var isPhase2: Bool = false
    // --------------------------------- //
    
    
    // ----------- Kalman Filter ------------ //
    var phase: Int = 0
    var indexCurrent: Int = 0
    var indexPast: Int = 0
    
    var indexSend: Int = 0
    var indexReceived: Int = 0
    
    var timeUpdateFlag: Bool = false
    var measurementUpdateFlag: Bool = false
    var isPhaseBreak: Bool = false

    var kalmanP: Double = 1
    var kalmanQ: Double = 0.3
    var kalmanR: Double = 6
    var kalmanK: Double = 1

    var updateHeading: Double = 0
    var headingKalmanP: Double = 0.5
    var headingKalmanQ: Double = 0.5
    var headingKalmanR: Double = 1
    var headingKalmanK: Double = 1
    
    var pastKalmanP: Double = 1
    var pastKalmanQ: Double = 0.3
    var pastKalmanR: Double = 6
    var pastKalmanK: Double = 1

    var pastHeadingKalmanP: Double = 0.5
    var pastHeadingKalmanQ: Double = 0.5
    var pastHeadingKalmanR: Double = 1
    var pastHeadingKalmanK: Double = 1

    var timeUpdatePosition = KalmanOutput()
    var measurementPosition = KalmanOutput()

    var timeUpdateOutput = FineLocationTrackingFromServer()
    var measurementOutput = FineLocationTrackingFromServer()
    
    var pastResult = [Double]()
    var pastBuildingLevel: [String] = ["",""]
    var currentBuildig: String = ""
    var currentLevel: String = ""
    var currentSpot: Int = 0
    
    var isMapMatching: Bool = false
    
    var isActiveService: Bool = true
    var isActiveRF: Bool = true
    var isAnswered: Bool = false
    var isFirstStart: Bool = true
    var isActiveKf: Bool = false
    var isStop: Bool = true
    
    var timeActiveRF: Double = 0
    var timeActiveUV: Double = 0
    var timeRequest: Double = 0
    var timePhaseChange: Double = 0
    var timeSleepRF: Double = 0
    var timeSleepUV: Double = 0
    var phaseUnstableCount: Double = 0
    let STOP_THRESHOLD: Double = 2
    let SLEEP_THRESHOLD: Double = 600 // 10분
    let SLEEP_THRESHOLD_RF: Double = 5 // 5s
    
    var lastTrackingTime: Int = 0
    var lastResult = FineLocationTrackingResult()
    let SQUARE_RANGE: Double = 10
    let HEADING_RANGE: Double = 50
    let HEADING_RANGE_TU : Double = 40
    var pastMatchingResult: [Double] = [0, 0, 0, 0]
    var matchingFailCount: Int = 0
    
    var muTime: Int = 0
    var muIndex: Int = 0
    var muX: Double = 0
    var muY: Double = 0
    var muHeading: Double = 0
    
    var currentTuResult = FineLocationTrackingResult()
    var pastTuResult = FineLocationTrackingResult()
    var headingBuffer = [Double]()
    var headingBufferMu = [Double]()
    var isMuHeadingCorrection: Bool = false
    let HEADING_BUFFER_SIZE: Int = 10
    
    public var serverResult: [Double] = [0, 0, 0]
    public var timeUpdateResult: [Double] = [0, 0, 0]
    
    let TU_SCALE_VALUE = 0.9

    // Output
    var lastServerResult = FineLocationTrackingFromServer()
    var outputResult = FineLocationTrackingResult()
    var flagPast: Bool = false
    
    // File for write Errors
    let fileManager = FileManager.default
    var textFile: URL?
    var errorLogs: String = ""
    let flagSaveError: Bool = true
    let flagSaveBle: Bool = true
    let flagSaveUVD: Bool = true
    
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
        startBLE()
        
        isFirstStart = true
        onStartFlag = false
        if (self.service == "FLT") {
            unitDRInfo = UnitDRInfo()
            unitDRGenerator.setMode(mode: mode)
//            unitDRGenerator.setMode(mode: "auto")
            
            if (mode == "pdr") {
                INIT_INPUT_NUM = 2
                VAR_INPUT_NUM = 5
            } else if (mode == "dr") {
                INIT_INPUT_NUM = 5
                VAR_INPUT_NUM = 10
            }
            UV_INPUT_NUM = INIT_INPUT_NUM
            
            onStartFlag = true
        }
        
        // File
        if (self.flagSaveError) {
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
        case "SD":
            numInput = 3
            interval = 1/2
        case "BD":
            numInput = 3
            interval = 1/2
        case "CLD":
            numInput = 3
            interval = 1/2
        case "FLD":
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
            interval = 1/2
        default:
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize the service\n"
            
            if (self.flagSaveError) {
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
            if (self.flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        } else {
            // Login Success
            let userInfo = UserInfo(user_id: self.user_id, device_model: deviceModel, os_version: osVersion)
            postUser(url: USER_URL, input: userInfo, completion: { [self] statusCode, returnedString in
                if (statusCode == 200) {
                    print("(Jupiter) Succes : User Login")
                    settingURL(server: self.serverType, os: self.osType)
                    startTimer()
                } else {
                    let localTime: String = getLocalTimeString()
                    let log: String = localTime + " , (Jupiter) Error : Load OS Type Error\n"
                    if (self.flagSaveError) {
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
            print("(Jupiter) Release-A")
        } else if (server == 0 && os == 1) {
            BASE_URL = RELEASE_URL_i
            print("(Jupiter) Release-i")
        } else if (server == 1 && os == 0) {
            BASE_URL = TEST_URL_A
            print("(Jupiter) Test-A")
        } else if (server == 1 && os == 1) {
            BASE_URL = TEST_URL_i
            print("(Jupiter) Test-i")
        } else {
            BASE_URL = RELEASE_URL_i
            print("(Jupiter) Release-i")
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
        case "SD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                let sdString = self.CLDtoSD(json: returnedString)
                completion(statusCode, sdString)
            })
        case "BD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                let bdString = self.CLDtoBD(json: returnedString)
                completion(statusCode, bdString)
            })
        case "CLD":
            let input = CoarseLevelDetection(user_id: self.user_id, mobile_time: currentTime)
            NetworkManager.shared.postCLD(url: CLD_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        case "FLD":
            let input = CoarseLocationEstimation(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id)
            NetworkManager.shared.postCLE(url: CLE_URL, input: input, completion: { statusCode, returnedString in
                let fldString = self.CLEtoFLD(json: returnedString)
                completion(statusCode, fldString)
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
            completion(500, "(Jupiter) Error : Invalid Service Name")
        }
    }
    
    public func getSpotResult(completion: @escaping (Int, String) -> Void) {
        let currentTime: Int = getCurrentTimeInMilliseconds()
        
        if (self.user_id != "") {
            let input = OnSpotAuthorization(user_id: self.user_id, mobile_time: currentTime)
            print("getSpotResult : \(input)")
            NetworkManager.shared.postOSA(url: OSA_URL, input: input, completion: { statusCode, returnedString in
                completion(statusCode, returnedString)
            })
        } else {
            completion(500, "(Jupiter) Error : Invalid User ID")
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
            if (self.flagSaveError) {
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
                    self.gyroRawX = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroRawY = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroRawZ = gyroZ
                }
            }
        } else {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Error : Fail to initialize gyroscope\n"
            if (self.flagSaveError) {
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
            if (self.flagSaveError) {
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
            if (self.flagSaveError) {
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
                    self.userAccX = -m.userAcceleration.x
                    self.userAccY = -m.userAcceleration.y
                    self.userAccZ = -m.userAcceleration.z
                    
                    self.gravX = m.gravity.x
                    self.gravY = m.gravity.y
                    self.gravZ = m.gravity.z
                    
                    self.roll = m.attitude.roll
                    self.pitch = m.attitude.pitch
                    self.yaw = m.attitude.yaw
                    
                    sensorData.gyro[0] = m.rotationRate.x
                    sensorData.gyro[1] = m.rotationRate.y
                    sensorData.gyro[2] = m.rotationRate.z
                    
                    collectData.gyro[0] = m.rotationRate.x
                    collectData.gyro[1] = m.rotationRate.y
                    collectData.gyro[2] = m.rotationRate.z
                    
                    sensorData.userAcc[0] = -m.userAcceleration.x*G
                    sensorData.userAcc[1] = -m.userAcceleration.y*G
                    sensorData.userAcc[2] = -m.userAcceleration.z*G
                    
                    collectData.userAcc[0] = -m.userAcceleration.x*G
                    collectData.userAcc[1] = -m.userAcceleration.y*G
                    collectData.userAcc[2] = -m.userAcceleration.z*G
                    
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
            if (self.flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
        
        if (sensorActive >= 5) {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + " , (Jupiter) Success : initialize sensors\n"
            if (self.flagSaveError) {
                self.errorLogs.append(log)
            } else {
               print(log)
            }
        }
    }
    
    func startBLE() {
        bleManager.setValidTime(mode: self.mode)
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
        
        if (updateTimer == nil && self.service == "FLT") {
            updateTimer = Timer.scheduledTimer(timeInterval: UPDATE_INTERVAL, target: self, selector: #selector(self.outputTimerUpdate), userInfo: nil, repeats: true)
        }
        
        if (osrTimer == nil && self.service == "FLT") {
            osrTimer = Timer.scheduledTimer(timeInterval: OSR_INTERVAL, target: self, selector: #selector(self.osrTimerUpdate), userInfo: nil, repeats: true)
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
        
        if (osrTimer != nil) {
            osrTimer!.invalidate()
            osrTimer = nil
        }
        
        if (requestTimer != nil) {
            requestTimer!.invalidate()
            requestTimer = nil
        }
        
        if (updateTimer != nil) {
            updateTimer!.invalidate()
            updateTimer = nil
        }
    }
    
    func enterSleepMode() {
        if (self.updateTimer != nil) {
            self.updateTimer!.invalidate()
            self.updateTimer = nil
        }
    }
    
    func wakeUpFromSleepMode() {
        if (self.updateTimer == nil && self.service == "FLT") {
            self.updateTimer = Timer.scheduledTimer(timeInterval: UPDATE_INTERVAL, target: self, selector: #selector(self.outputTimerUpdate), userInfo: nil, repeats: true)
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
    
    @objc func outputTimerUpdate() {
        self.tracking(input: self.outputResult, isPast: self.flagPast)
    }
    
    @objc func receivedForceTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds() - (Int(bleManager.BLE_VALID_TIME)/2)
        bleManager.trimBleData()
        
        var bleDictionary = bleManager.bleAvg
        if (deviceModel == "iPhone 13 Mini" || deviceModel == "iPhone 12 Mini" || deviceModel == "iPhone X") {
            bleDictionary.keys.forEach { bleDictionary[$0] = bleDictionary[$0]! + 7 }
        }
        
        let bleCheckTime = Double(currentTime)
        let discoveredTime = bleManager.bleDiscoveredTime
        let diffBleTime = (bleCheckTime - discoveredTime)*1e-3
        
        if (self.flagSaveBle) {
            let localTime: String = getLocalTimeString()
            let log: String = localTime + "__(Jupiter) BLE Check__\(diffBleTime)__\(bleCheckTime)__\(discoveredTime)__\(bleManager.bleCheck)\n"
            self.errorLogs.append(log)
        }

        if (!bleDictionary.isEmpty) {
            self.timeActiveRF = 0
            self.timeSleepRF = 0
            
            self.isActiveRF = true
            self.isActiveService = true
            
            self.wakeUpFromSleepMode()
            if (self.isActiveService) {
                let data = ReceivedForce(user_id: self.user_id, mobile_time: currentTime, ble: bleDictionary, pressure: self.pressure)
                
                inputReceivedForce.append(data)
                if ((inputReceivedForce.count-1) == SPATIAL_INPUT_NUM) {
                    inputReceivedForce.remove(at: 0)
                    NetworkManager.shared.putReceivedForce(url: RF_URL, input: inputReceivedForce, completion: { [self] statusCode, returnedStrig in
                        if (statusCode != 200) {
                            if (self.flagSaveError) {
                                let localTime: String = getLocalTimeString()
                                let log: String = localTime + " , (Jupiter) Error : Fail to send BLE\n"
                                self.errorLogs.append(log)
                            }
                        }
                    })
                    inputReceivedForce = [ReceivedForce(user_id: "", mobile_time: 0, ble: [:], pressure: 0)]
                }
            }
        } else {
            self.timeActiveRF += RF_INTERVAL
            if (self.timeActiveRF >= SLEEP_THRESHOLD_RF) {
                self.isActiveRF = false
                self.timeActiveRF = 0
            }
            
            self.timeSleepRF += RF_INTERVAL
            if (self.timeSleepRF >= SLEEP_THRESHOLD) {
                print("(Jupiter) Enter Sleep Mode")
                self.isActiveService = false
                self.timeSleepRF = 0
                
                self.enterSleepMode()
            }
        }
    }
    
    @objc func userVelocityTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        if (onStartFlag) {
            unitDRInfo = unitDRGenerator.generateDRInfo(sensorData: sensorData)
            if (self.flagSaveUVD) {
                let uvCheckTime = Double(currentTime)
                let localTime: String = getLocalTimeString()
                let log: String = localTime + "__(Jupiter) generateDRInfo sensor__\(uvCheckTime)__\(sensorData)\n"
                let log2: String = localTime + "__(Jupiter) generateDRInfo unitDRInfo__\(uvCheckTime)__\(unitDRInfo)\n"
                self.errorLogs.append(log)
                self.errorLogs.append(log2)
            }
        }
        
        if (unitDRInfo.isIndexChanged) {
            if (self.flagSaveUVD) {
                let uvCheckTime = Double(currentTime)
                let localTime: String = getLocalTimeString()
                let log: String = localTime + "__(Jupiter) isIndexChanged__\(uvCheckTime)__\(unitDRInfo)\n"
                self.errorLogs.append(log)
            }
            self.headingBuffer.append(unitDRInfo.heading)
            self.headingBufferMu.append(unitDRInfo.heading)
            let isNeedHeadingCorrection: Bool = self.checkHeadingCorrection(buffer: self.headingBuffer)
            self.isMuHeadingCorrection = self.checkHeadingCorrection(buffer: self.headingBufferMu)
            
            self.wakeUpFromSleepMode()
            self.timeActiveUV = 0
            self.timeSleepUV = 0
            
            self.isStop = false
            self.isActiveService = true
            
            self.travelingOsrDistance += unitDRInfo.length
            
            displayOutput.isIndexChanged = unitDRInfo.isIndexChanged
            displayOutput.indexTx = unitDRInfo.index
            displayOutput.length = unitDRInfo.length
            displayOutput.velocity = unitDRInfo.velocity * 3.6
            
            let data = UserVelocity(user_id: self.user_id, mobile_time: currentTime, index: unitDRInfo.index, length: unitDRInfo.length, heading: unitDRInfo.heading, looking: unitDRInfo.lookingFlag)
            timeUpdateOutput.index = unitDRInfo.index
            
            // Kalman Filter
            let diffHeading = unitDRInfo.heading - preUnitHeading
            let curUnitDRLength = unitDRInfo.length
            
            if (self.isActiveService) {
                inputUserVelocity.append(data)
                
                // Time Update
                if (self.isActiveKf) {
                    if (timeUpdateFlag) {
                        let tuOutput = timeUpdate(length: curUnitDRLength, diffHeading: diffHeading, mobileTime: currentTime, isNeedHeadingCorrection: isNeedHeadingCorrection)
                        var tuResult = fromServerToResult(fromServer: tuOutput, velocity: displayOutput.velocity)
                        
                        self.timeUpdateResult[0] = tuResult.x
                        self.timeUpdateResult[1] = tuResult.y
                        self.timeUpdateResult[2] = tuResult.absolute_heading
                        
                        self.currentTuResult = tuResult
                        if (bleManager.bluetoothReady) {
                            let trackingTime = getCurrentTimeInMilliseconds()
                            tuResult.mobile_time = trackingTime
                            self.outputResult = tuResult
                            self.flagPast = false
                            print("(Jupiter) outputResult (tu) : \(self.outputResult.level_name)")
                        }
                    }
                }
                preUnitHeading = unitDRInfo.heading
                
                // Put UV
                if ((inputUserVelocity.count-1) >= UV_INPUT_NUM) {
                    inputUserVelocity.remove(at: 0)
                    
                    if (self.flagSaveUVD) {
                        let uvCheckTime = Double(currentTime)
                        let localTime: String = getLocalTimeString()
                        let log: String = localTime + "__(Jupiter) UVD Check__\(uvCheckTime)__\(inputUserVelocity)\n"
                        self.errorLogs.append(log)
                    }
                    
//                    if (self.isActiveKf) {
//                        let correctedTuResult = self.correct(building: timeUpdateOutput.building_name, level: timeUpdateOutput.level_name, x: timeUpdateOutput.x, y: timeUpdateOutput.y, heading: timeUpdateOutput.absolute_heading, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE_TU)
//                        self.timeUpdatePosition.x = correctedTuResult.xyh[0]
//                        self.timeUpdatePosition.y = correctedTuResult.xyh[1]
//                        self.timeUpdatePosition.heading = correctedTuResult.xyh[2]
//
//                        self.timeUpdateResult[0] = self.timeUpdatePosition.x
//                        self.timeUpdateResult[1] = self.timeUpdatePosition.y
//                        self.timeUpdateResult[2] = self.timeUpdatePosition.heading
//                    }
                    
                    NetworkManager.shared.putUserVelocity(url: UV_URL, input: inputUserVelocity, completion: { [self] statusCode, returnedString in
                        if (statusCode == 200) {
                            floorUpdateRequestFlag = true
                            floorUpdateRequestTimeStack = 0
                            
                            self.pastTuResult = self.currentTuResult
                            indexSend = Int(returnedString) ?? 0
                            isAnswered = true
                        } else {
                            if (self.flagSaveError) {
                                let localTime: String = getLocalTimeString()
                                let log: String = localTime + " , (Jupiter) Error : Fail to send sensor measurements\n"
                                self.errorLogs.append(log)
                            }
                        }
                    })
                    inputUserVelocity = [UserVelocity(user_id: user_id, mobile_time: 0, index: 0, length: 0, heading: 0, looking: true)]
                }
            }
        } else {
            // UV가 발생하지 않음
            self.timeActiveUV += UV_INTERVAL
            if (self.timeActiveUV >= STOP_THRESHOLD) {
                self.isStop = true
                self.timeActiveUV = 0
                displayOutput.velocity = 0
            }
            
            self.timeSleepUV += UV_INTERVAL
            if (self.timeSleepUV >= SLEEP_THRESHOLD) {
                print("(Jupiter) Enter Sleep Mode")
                self.isActiveService = false
                self.timeSleepUV = 0
                
                self.enterSleepMode()
            }
        }
    }
    
    @objc func requestTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        
        // UV Control
        if (self.phase == 4) {
            UV_INPUT_NUM = VAR_INPUT_NUM
            INDEX_THRESHOLD = 11
        } else {
            UV_INPUT_NUM = INIT_INPUT_NUM
            INDEX_THRESHOLD = 6
        }
        
        if (self.isActiveService) {
            if (self.isStop && isActiveKf) {
                // Stop State
                self.updateLastResult(currentTime: currentTime)
            } else {
                // Moving State
                if (self.isPhase2) {
                    self.timeRequest += RQ_INTERVAL
                    if (self.timeRequest >= 1.9) {
                        self.timeRequest = 0
                        
                        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuildig, level_name: self.currentLevel, spot_id: self.currentSpot, phase: 2)
                        print("(Jupiter) Phase 2 Input : \(input)")
                        
                        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                            if (statusCode == 200) {
                                let result = jsonToResult(json: returnedString)
                                if (result.mobile_time > self.preOutputMobileTime) {
                                    print("(Jupiter) Phase 2 Result : \(result)")
                                    displayOutput.indexRx = result.index
                                    
                                    self.phase = result.phase
                                    self.currentBuildig = result.building_name
                                    self.currentLevel = result.level_name
                                    self.preOutputMobileTime = result.mobile_time
                                    
                                    var resultCorrected = self.correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], isMu: false, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                                    resultCorrected.xyh[2] = compensateHeading(heading: resultCorrected.xyh[2], mode: self.mode)
                                    
                                    self.serverResult[0] = result.x
                                    self.serverResult[1] = result.y
                                    self.serverResult[2] = result.absolute_heading
                                }
                            }
                        })
                    }
                    self.isPhase2 = false
                }
                else if (self.phase < 4) {
                    // Phase 1 ~ 3
                    // 2s 마다 요청
                    self.timeRequest += RQ_INTERVAL
                    if (self.timeRequest >= 1.9) {
                        if (self.isActiveKf) {
                            self.kalmanR = 0.01
                            self.headingKalmanR = 0.01
                            self.isPhaseBreak = true
                        }
                        self.currentSpot = 0
                        self.timeRequest = 0
                        
                        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuildig, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase)
                        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                            if (statusCode == 200) {
                                let result = jsonToResult(json: returnedString)
                                if (result.mobile_time > self.preOutputMobileTime) {
                                    displayOutput.indexRx = result.index
                                    
                                    self.phase = result.phase
                                    self.currentBuildig = result.building_name
                                    self.currentLevel = result.level_name
                                    self.preOutputMobileTime = result.mobile_time
                                    
                                    var resultCorrected = self.correct(building: result.building_name, level: result.level_name, x: result.x, y: result.y, heading: result.absolute_heading, tuXY: [0,0], isMu: false, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                                    resultCorrected.xyh[2] = compensateHeading(heading: resultCorrected.xyh[2], mode: self.mode)
                                    
                                    self.serverResult[0] = result.x
                                    self.serverResult[1] = result.y
                                    self.serverResult[2] = result.absolute_heading
                                    
                                    if (!self.isActiveKf) {
                                        let trackingTime = getCurrentTimeInMilliseconds()
                                        var finalResult = fromServerToResult(fromServer: result, velocity: displayOutput.velocity)
                                        finalResult.mobile_time = trackingTime
                                        
                                        self.outputResult = finalResult
                                        self.flagPast = false
                                    } else {
//                                        // Check Building Level Change
//                                        let isBuildingLevelChanged = self.checkBuildingLevelChange(currentBuillding: result.building_name, currentLevel: result.level_name, pastBuilding: self.pastBuildingLevel[0], pastLevel: self.pastBuildingLevel[0])
//                                        if (isBuildingLevelChanged) {
//
//                                        }
                                        if (result.building_name != self.pastBuildingLevel[0] || result.level_name != self.pastBuildingLevel[1]) {
                                            if (!self.pastResult.isEmpty) {
                                                // FinalResult -> Result from Server when Building Level Changed
                                                var timUpdateOutputCopy = self.timeUpdateOutput
                                                timUpdateOutputCopy.phase = result.phase
                                                timUpdateOutputCopy.building_name = result.building_name
                                                timUpdateOutputCopy.level_name = result.level_name
                                                timUpdateOutputCopy.mobile_time = result.mobile_time

                                                var updatedResult = fromServerToResult(fromServer: timUpdateOutputCopy, velocity: displayOutput.velocity)
                                                self.timeUpdateOutput = timUpdateOutputCopy

                                                let trackingTime = getCurrentTimeInMilliseconds()
                                                updatedResult.mobile_time = trackingTime

                                                self.outputResult = updatedResult
                                                self.flagPast = false
                                                print("(Jupiter) outputResult (Phase 1 ~ 3 Yes KF if) : \(self.outputResult.level_name)")
                                            }
                                        } else {
                                            var timUpdateOutputCopy = self.timeUpdateOutput
                                            timUpdateOutputCopy.phase = result.phase
                                            timUpdateOutputCopy.building_name = result.building_name
                                            timUpdateOutputCopy.level_name = result.level_name
                                            timUpdateOutputCopy.mobile_time = result.mobile_time

                                            var updatedResult = fromServerToResult(fromServer: timUpdateOutputCopy, velocity: displayOutput.velocity)
                                            self.timeUpdateOutput = timUpdateOutputCopy

                                            let trackingTime = getCurrentTimeInMilliseconds()
                                            updatedResult.mobile_time = trackingTime

                                            self.outputResult = updatedResult
                                            self.flagPast = false
                                        }
                                    }
                                    self.lastServerResult = result
                                    self.pastBuildingLevel = [result.building_name, result.level_name]
                                }
                            }
                        })
                    }
                } else {
                    // Phase 4
                    if (self.isAnswered) {
                        self.isAnswered = false
                        
                        self.nowTime = currentTime
                        
                        let input = FineLocationTracking(user_id: self.user_id, mobile_time: currentTime, sector_id: self.sector_id, building_name: self.currentBuildig, level_name: self.currentLevel, spot_id: self.currentSpot, phase: self.phase)
                        NetworkManager.shared.postFLT(url: FLT_URL, input: input, completion: { [self] statusCode, returnedString in
                            if (statusCode == 200) {
                                let result = jsonToResult(json: returnedString)
                                
                                if ((self.nowTime - result.mobile_time) <= RECENT_THRESHOLD) {
                                    if ((result.index - self.indexPast) < INDEX_THRESHOLD) {
                                        
                                        if (result.mobile_time > self.preOutputMobileTime) {
                                            if (!self.isActiveKf && result.phase == 4) {
                                                self.isActiveKf = true
                                            }
                                            
                                            self.phase = result.phase
                                            self.currentBuildig = result.building_name
                                            self.currentLevel = result.level_name
                                            self.preOutputMobileTime = result.mobile_time
                                            self.lastServerResult = result
                                            
                                            if (self.isActiveKf && result.phase == 4) {
                                                if (!(result.x == 0 && result.y == 0)) {
                                                    if (self.isPhaseBreak) {
                                                        self.kalmanR = 6
                                                        self.headingKalmanR = 1
                                                        self.isPhaseBreak = false
                                                    }
                                                    
                                                    // Measurment Update
                                                    let diffIndex = abs(indexSend - result.index)
                                                    if (measurementUpdateFlag && (diffIndex<1)) {
                                                        displayOutput.indexRx = result.index
                                                        
                                                        muTime = result.mobile_time
                                                        muIndex = result.index
                                                        muX = result.x
                                                        muY = result.y
                                                        muHeading = result.absolute_heading
                                                        
                                                        if (self.flagSaveBle) {
                                                            let localTime: String = getLocalTimeString()
                                                            let log: String = localTime + "__(Jupiter) Kalman MU__\(self.nowTime)__\(result.mobile_time)__\(result.index)__\(result.x)__\(result.y)__\(result.absolute_heading)\n"
                                                            self.errorLogs.append(log)
                                                        }

                                                        // Measurement Update 하기전에 현재 Time Update 위치를 고려
                                                        var resultForMu = result
                                                        self.serverResult[0] = result.x
                                                        self.serverResult[1] = result.y
                                                        self.serverResult[2] = result.absolute_heading
                                                        
                                                        resultForMu.absolute_heading = compensateHeading(heading: resultForMu.absolute_heading, mode: self.mode)
                                                        var resultCorrected = self.correct(building: resultForMu.building_name, level: resultForMu.level_name, x: resultForMu.x, y: resultForMu.y, heading: resultForMu.absolute_heading, tuXY: [self.pastTuResult.x, self.pastTuResult.y], isMu: true, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
                                                        
                                                        if (self.currentTuResult.mobile_time != 0 && self.pastTuResult.mobile_time != 0) {
                                                            let dx = self.currentTuResult.x - self.pastTuResult.x
                                                            let dy = self.currentTuResult.y - self.pastTuResult.y
                                                            self.currentTuResult.absolute_heading = compensateHeading(heading: self.currentTuResult.absolute_heading, mode: self.mode)
                         
                                                            self.pastTuResult.absolute_heading = compensateHeading(heading: self.pastTuResult.absolute_heading, mode: self.mode)
                                                            
                                                            let dh = self.currentTuResult.absolute_heading - self.pastTuResult.absolute_heading
                                                            
                                                            resultForMu.x = resultCorrected.xyh[0] + dx
                                                            resultForMu.y = resultCorrected.xyh[1] + dy
                                                            resultForMu.absolute_heading = resultCorrected.xyh[2] + dh
                                                            
                                                            let localTime = getLocalTimeString()
//                                                            print(localTime + " (Jupiter) // indexRx : \(resultForMu.index) // dx : \(dx) // dy : \(dy) // dh : \(dh)")
                                                        }
                                                        let trackingTime = getCurrentTimeInMilliseconds()
                                                        
                                                        let muOutput = measurementUpdate(timeUpdatePosition: timeUpdatePosition, serverOutput: resultForMu, originalResult: resultCorrected.xyh, isNeedHeadingCorrection: self.isMuHeadingCorrection)
                                                        var muResult = fromServerToResult(fromServer: muOutput, velocity: displayOutput.velocity)
                                                        
                                                        // 비교 : Server (After MM) vs Server + dxdy (After MM)
//                                                        let diffX = resultCorrected.xyh[0] - muResult.x
//                                                        let diffY = resultCorrected.xyh[1] - muResult.y
//                                                        let diffH = resultCorrected.xyh[2] - muResult.absolute_heading
//                                                        let diffXY: Double = sqrt(diffX*diffX + diffY*diffY)
//                                                        let localTime = getLocalTimeString()
//                                                        print(localTime + " (Jupiter) // diffXY : \(diffXY) // diffH : \(diffH)")
                                                        
//                                                        self.serverResult[0] = muResult.x
//                                                        self.serverResult[1] = muResult.y
//                                                        self.serverResult[2] = muResult.absolute_heading
                                                        muResult.mobile_time = trackingTime
                                                        
                                                        self.outputResult = muResult
                                                        self.flagPast = false
                                                        print("(Jupiter) outputResult (mu) : \(self.outputResult.level_name)")
                                                    }
                                                    timeUpdatePositionInit(serverOutput: result)
                                                }
                                            }
                                        }
                                    }
                                    self.indexPast = result.index
                                    self.pastBuildingLevel = [result.building_name, result.level_name]
                                }
                            }
                        })
                    } else {
                        if(!isActiveKf) {
                            self.updateLastResult(currentTime: currentTime)
                        }
                    }
                }
            }
        }
    }
    
    @objc func osrTimerUpdate() {
        let currentTime = getCurrentTimeInMilliseconds()
        let input = OnSpotRecognition(user_id: self.user_id, mobile_time: currentTime)
        NetworkManager.shared.postOSR(url: OSR_URL, input: input, completion: { [self] statusCode, returnedString in
            if (statusCode == 200) {
                let result = decodeOSR(json: returnedString)
                if (result.building_name != "" && result.level_name != "") {
                    print("(Jupiter) OnSpot : \(result)")
                    let isOnSpot = isOnSpotRecognition(result: result)
                    // Level Changed Check
                    // true : Go to Phase 2
                    if (isOnSpot.isOn) {
                        let levelDestination = isOnSpot.levelDestination
                        if (result.spot_id != self.lastOsrId) {
                            // Different Spot Detected
                            self.isPhase2 = true
                            self.phase = 2
                            self.currentLevel = levelDestination
                            self.outputResult.level_name = levelDestination
                            self.currentSpot = result.spot_id

                            self.lastOsrId = result.spot_id
                            self.lastOsrTime = result.mobile_time

                            self.travelingOsrDistance = 0
                            print("(Jupiter) isOnSpotRecognition : \(isOnSpot) , \(self.phase) , \(self.isPhase2)")
                        } else {
                            // Same Spot Detected
                            if (self.travelingOsrDistance >= 50) {
                                self.isPhase2 = true
                                self.phase = 2
                                self.currentLevel = levelDestination
                                self.outputResult.level_name = levelDestination
                                self.currentSpot = result.spot_id

                                self.lastOsrId = result.spot_id
                                self.lastOsrTime = result.mobile_time

                                self.travelingOsrDistance = 0
                                print("(Jupiter) isOnSpotRecognition : \(isOnSpot) , \(self.phase) , \(self.isPhase2)")
                            }
                        }
                    }
                }
            }
        })
    }
    
    func isOnSpotRecognition(result: OnSpotRecognitionResult) -> (isOn: Bool, levelDestination: String) {
        var isOn: Bool = false
        
        let mobile_time = result.mobile_time
        let building_name = result.building_name
        let level_name = result.level_name
        let linked_level_name = result.linked_level_name
        let spot_id = result.spot_id
        
        let levelArray: [String] = [level_name, linked_level_name]
        var levelDestination: String = ""
        for i in 0..<levelArray.count {
            if levelArray[i] != self.currentLevel {
                levelDestination = levelArray[i]
                isOn = true
            }
        }
        
        // Up or Down Direction
//        let isUnderCurrentLevel = checkUnderground(levelName: self.currentLevel)
//        let isUnderDestinationLevel = checkUnderground(levelName: levelDestination)
        let currentLevelNum: Int = getLevelNumber(levelName: self.currentLevel)
        let destinationLevelNum: Int = getLevelNumber(levelName: levelDestination)
        let levelDirection: String = checkLevelDirection(currentLevel: currentLevelNum, destinationLevel: destinationLevelNum)
        levelDestination = levelDestination + levelDirection
        print("(Jupiter) Use Level Map : \(levelDestination)")
        
        return (isOn, levelDestination)
    }
    
    func getLevelNumber(levelName: String) -> Int {
        if (levelName[levelName.startIndex] == "B") {
            // 지하
            var levelNameCopy: String = levelName
            var currentLevelTemp = String(levelNameCopy.removeFirst())
            var currentLevelNum = Int(currentLevelTemp) ?? 0
            currentLevelNum = (-1*currentLevelNum)-1
            return currentLevelNum
        } else {
            // 지상
            var levelNameCopy: String = levelName
            var currentLevelTemp = String(levelNameCopy.removeLast())
            var currentLevelNum = Int(currentLevelTemp) ?? 0
            currentLevelNum = currentLevelNum+1
            return currentLevelNum
        }
    }
    
    func checkLevelDirection(currentLevel: Int, destinationLevel: Int) -> String {
        var levelDirection: String = ""
        var diffLevel: Int = destinationLevel - currentLevel
        if (diffLevel > 0) {
            levelDirection = "_D"
        }
        
        return levelDirection
    }
    
    func removeLevelDirectionString(levelName: String) -> String {
        var levelToReturn: String = levelName
        if (levelToReturn.contains("_D")) {
            levelToReturn = levelName.replacingOccurrences(of: "_D", with: "")
        }
        return levelToReturn
    }
    
    
    func checkUnderground(levelName: String) -> Bool {
        if (levelName[levelName.startIndex] == "B") {
            return true
        } else {
            return false
        }
    }
    
    func checkUpDirection(currentLevel: String, isUnderCurrentLevel: Bool, levelDestination: String, isUnderDestinationLevel: Bool) -> Bool {
        var isUpDirection: Bool = false
        
        if (!isUnderCurrentLevel && !isUnderDestinationLevel) {
            // 둘다 지상인 경우
            let currentLevelNum = Int(String(currentLevel[currentLevel.startIndex])) ?? 0
            let destinationLevelNum = Int(String(levelDestination[levelDestination.startIndex])) ?? 0
        } else if (isUnderCurrentLevel && isUnderDestinationLevel){
            // 둘다 지하인 경우
            let currentLevelNum = Int(String(currentLevel[currentLevel.endIndex])) ?? 0
            let destinationLevelNum = Int(String(levelDestination[levelDestination.endIndex])) ?? 0
        } else{
            // 둘 중 하나만 지상 혹은 지하인 경우
            if (isUnderCurrentLevel) {
                // 현재 층이 지하 -> 목적지는 지상
                isUpDirection = true
            } else {
                // 현재 층이 지상 -> 목적지는 지하
                isUpDirection = false
            }
        }
        
        return isUpDirection
    }
    
    func checkBuildingLevelChange(currentBuillding: String, currentLevel: String, pastBuilding: String, pastLevel: String) -> Bool {
        if (currentBuillding == pastBuilding) && (currentLevel == pastLevel) {
            return false
        } else {
            return true
        }
    }
    
    func updateLastResult(currentTime: Int) {
        let diffUpdatedTime: Int = currentTime - self.lastTrackingTime
        if (diffUpdatedTime >= 200) {
            if (self.lastTrackingTime != 0 && self.isActiveRF) {
                let trackingTime = getCurrentTimeInMilliseconds()
                self.lastResult.mobile_time = trackingTime
                self.lastTrackingTime = trackingTime
                
                self.outputResult = self.lastResult
                self.flagPast = true
                
                if (flagSaveError) {
                    let localTime: String = getLocalTimeString()
                    let log: String = localTime + " , (Jupiter) Warnings : Past Result , Stop = \(self.isStop)\n"
                    self.errorLogs.append(log)
                }
            } else {
                if (isFirstStart) {
                    let key: String = "JupiterLastResult_\(self.sector_id)"
                    if let lastKnownResult: String = UserDefaults.standard.object(forKey: key) as? String {
                        let currentTime = getCurrentTimeInMilliseconds()
                        let result = jsonForTracking(json: lastKnownResult)
                        
                        if (currentTime - result.mobile_time) < 1000*3600*12 {
                            var updatedResult = result
                            updatedResult.mobile_time = currentTime
                            updatedResult.index = 0
                            updatedResult.phase = 0
                            
                            let trackingTime = currentTime
                            updatedResult.mobile_time = trackingTime
                            
                            self.outputResult = updatedResult
                            self.flagPast = false
                        }
                    } else {
                        if (self.flagSaveError) {
                            let localTime: String = getLocalTimeString()
                            let log: String = localTime + " , (Jupiter) Warnings : Empty Last Result\n"
                            self.errorLogs.append(log)
                        }
                    }
                    isFirstStart = false
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
    
    private func correct(building: String, level: String, x: Double, y: Double, heading: Double, tuXY: [Double], isMu: Bool, mode: String, isPast: Bool, HEADING_RANGE: Double) -> (isSuccess: Bool, xyh: [Double]) {
        var isSuccess: Bool = false
        var xyh: [Double] = [x, y, heading]
        var levelCopy: String = self.removeLevelDirectionString(levelName: level)
        let key: String = "\(building)_\(levelCopy)"
        
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
            var failArray = [[Double]]()
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
                                        if (heading > 270 && (mapHeading >= 0 && mapHeading < 90)) {
                                            diffHeading.append(abs(heading - (mapHeading+360)))
                                        } else if (mapHeading > 270 && (heading >= 0 && heading < 90)) {
                                            diffHeading.append(abs(mapHeading - (heading+360)))
                                        } else {
                                            diffHeading.append(abs(heading - mapHeading))
                                        }
                                    }
                                }
                                
                                if (!diffHeading.isEmpty) {
                                    let idxHeading = diffHeading.firstIndex(of: diffHeading.min()!)
                                    let minHeading = Double(headingData[idxHeading!])!
                                    idh[2] = minHeading
                                    if (mode == "dr") {
                                        if (heading > 270 && (minHeading >= 0 && minHeading < 90)) {
                                            if (abs(heading-360) >= HEADING_RANGE) {
                                                isValidIdh = false
                                            }
                                        } else if (minHeading > 270 && (heading >= 0 && heading < 90)) {
                                            if (abs(minHeading-360) >= HEADING_RANGE) {
                                                isValidIdh = false
                                            }
                                        } else {
                                            if (abs(heading-minHeading) >= HEADING_RANGE) {
                                                isValidIdh = false
                                            }
                                        }
                                    }
                                    path[2] = minHeading
                                    path[3] = 1
                                }
                            }
                            if (isValidIdh) {
                                idhArray.append(idh)
                                pathArray.append(path)
                            } else {
                                failArray.append(idh)
                            }
                        }
                    }
                }
                
                if (!idhArray.isEmpty) {
                    let sortedIdh = idhArray.sorted(by: {$0[1] < $1[1] })
                    var index: Int = 0
                    var correctedHeading: Double = heading
                    // Original
                    if (!sortedIdh.isEmpty) {
                        let minData: [Double] = sortedIdh[0]
                        index = Int(minData[0])
                        if (mode == "dr") {
                            correctedHeading = minData[2]
                        } else {
                            correctedHeading = heading
                        }
                    }
                    
                    if (!sortedIdh.isEmpty) {
                        if (isMu) {
                            // In Measurement Update
                            var minData: [Double] = sortedIdh[0]
                            index = Int(minData[0])
                            
                            var minDistance: Double = 40
                            for idx in 0..<sortedIdh.count {
                                let cand: [Double] = sortedIdh[idx]
                                let idxCand = Int(cand[0])
                                let xyCand = [roadX[idxCand], roadY[idxCand]]
                                
                                let diffXY = sqrt((tuXY[0] - xyCand[0])*(tuXY[0] - xyCand[0]) + (tuXY[1] - xyCand[1])*(tuXY[1] - xyCand[1]))
                                if (diffXY < minDistance) {
                                    index = idxCand
                                    correctedHeading = cand[2]
                                    
                                    minDistance = diffXY
                                }
                            }
                            
                            if (mode == "dr") {
                                correctedHeading = minData[2]
                            } else {
                                correctedHeading = heading
                            }
                            
                        } else {
                            // Other Case
                            let minData: [Double] = sortedIdh[0]
                            index = Int(minData[0])
                            if (mode == "dr") {
                                correctedHeading = minData[2]
                            } else {
                                correctedHeading = heading
                            }
                        }
                    }
                    
                    isSuccess = true
                    xyh = [roadX[index], roadY[index], correctedHeading]
                }
            }
        }
        return (isSuccess, xyh)
    }
    
    func checkHeadingCorrection(buffer: [Double]) -> Bool {
        if (buffer.count >= HEADING_BUFFER_SIZE) {
            let firstHeading: Double = buffer.first ?? 0.0
            let lastHeading: Double = buffer.last ?? 0.0
            
            self.headingBuffer.removeFirst()
            
            let diffHeading: Double = abs(lastHeading - firstHeading)
            if (diffHeading < 10.0) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
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
        kalmanR = 6
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

    func timeUpdate(length: Double, diffHeading: Double, mobileTime: Int, isNeedHeadingCorrection: Bool) -> FineLocationTrackingFromServer {
        updateHeading = timeUpdatePosition.heading + diffHeading
        
        var dx = length*cos(updateHeading*D2R)
        var dy = length*sin(updateHeading*D2R)
        
        if (self.phase != 4 && self.mode == "dr") {
            dx = dx * TU_SCALE_VALUE
            dy = dy * TU_SCALE_VALUE
        }
        
        timeUpdatePosition.x = timeUpdatePosition.x + dx
        timeUpdatePosition.y = timeUpdatePosition.y + dy
        timeUpdatePosition.heading = updateHeading
        
        var timeUpdateCopy = timeUpdatePosition
        let correctedTuCopy = self.correct(building: timeUpdateOutput.building_name, level: timeUpdateOutput.level_name, x: timeUpdatePosition.x, y: timeUpdatePosition.y, heading: timeUpdatePosition.heading, tuXY: [0,0], isMu: false, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        if (correctedTuCopy.isSuccess && self.mode == "dr") {
            timeUpdateCopy.x = correctedTuCopy.xyh[0]
            timeUpdateCopy.y = correctedTuCopy.xyh[1]
            if (isNeedHeadingCorrection && self.phase < 4) {
                timeUpdateCopy.heading = correctedTuCopy.xyh[2]
            }
        }
        timeUpdatePosition = timeUpdateCopy
        
        kalmanP += kalmanQ
        headingKalmanP += headingKalmanQ

        timeUpdateOutput.x = timeUpdatePosition.x
        timeUpdateOutput.y = timeUpdatePosition.y
        timeUpdateOutput.absolute_heading = updateHeading
        timeUpdateOutput.mobile_time = mobileTime

        measurementUpdateFlag = true

        return timeUpdateOutput
    }

    func measurementUpdate(timeUpdatePosition: KalmanOutput, serverOutput: FineLocationTrackingFromServer, originalResult: [Double], isNeedHeadingCorrection: Bool) -> FineLocationTrackingFromServer {
        var serverOutputCopy = serverOutput
        serverOutputCopy.absolute_heading = compensateHeading(heading: serverOutputCopy.absolute_heading, mode: self.mode)
        
        // ServerOutputHat을 맵매칭
        let correctedOutput = self.correct(building: serverOutputCopy.building_name, level: serverOutputCopy.level_name, x: serverOutputCopy.x, y: serverOutputCopy.y, heading: serverOutputCopy.absolute_heading, tuXY: [0, 0], isMu: false, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        var correctedServerOutput: FineLocationTrackingFromServer = serverOutputCopy
        
        var timeUpdateHeadingCopy = timeUpdatePosition.heading
        timeUpdateHeadingCopy = compensateHeading(heading: timeUpdateHeadingCopy, mode: self.mode)
        
        if (correctedOutput.isSuccess) {
            correctedServerOutput.x = correctedOutput.xyh[0]
            correctedServerOutput.y = correctedOutput.xyh[1]
            correctedServerOutput.absolute_heading = correctedOutput.xyh[2]
            
            if (self.mode == "dr") {
                if (timeUpdateHeadingCopy >= 270 && correctedServerOutput.absolute_heading == 0) {
                    correctedServerOutput.absolute_heading = 360
                }
            }
        } else {
            correctedServerOutput.absolute_heading = originalResult[2]
        }
        
        measurementOutput = correctedServerOutput

        kalmanK = kalmanP / (kalmanP + kalmanR)
        headingKalmanK = headingKalmanP / (headingKalmanP + headingKalmanR)

        measurementPosition.x = timeUpdatePosition.x + kalmanK * (Double(correctedServerOutput.x) - timeUpdatePosition.x)
        measurementPosition.y = timeUpdatePosition.y + kalmanK * (Double(correctedServerOutput.y) - timeUpdatePosition.y)
        if (isNeedHeadingCorrection) {
            updateHeading = timeUpdateHeadingCopy + headingKalmanK * (correctedServerOutput.absolute_heading - timeUpdateHeadingCopy)
        } else {
            updateHeading = timeUpdateHeadingCopy
        }
        

        measurementOutput.x = measurementPosition.x
        measurementOutput.y = measurementPosition.y
        kalmanP -= kalmanK * kalmanP
        headingKalmanP -= headingKalmanK * headingKalmanP
        
        let measurementOutputCorrected = self.correct(building: measurementOutput.building_name, level: measurementOutput.level_name, x: measurementOutput.x, y: measurementOutput.y, heading: updateHeading, tuXY: [0,0], isMu: false, mode: self.mode, isPast: false, HEADING_RANGE: self.HEADING_RANGE)
        
        if (measurementOutputCorrected.isSuccess) {
            let diffX = timeUpdatePosition.x - measurementOutputCorrected.xyh[0]
            let diffY = timeUpdatePosition.y - measurementOutputCorrected.xyh[1]
            let diffXY = sqrt(diffX*diffX + diffY*diffY)
            
            if (diffXY > 30) {
                // Use Server Result
                self.timeUpdatePosition.x = originalResult[0]
                self.timeUpdatePosition.y = originalResult[1]
                self.timeUpdatePosition.heading = originalResult[2]
                
                measurementOutput.x = originalResult[0]
                measurementOutput.y = originalResult[1]
                updateHeading = originalResult[2]
                
                backKalmanParam()
            } else {
                self.timeUpdatePosition.x = measurementOutputCorrected.xyh[0]
                self.timeUpdatePosition.y = measurementOutputCorrected.xyh[1]
                self.timeUpdatePosition.heading = measurementOutputCorrected.xyh[2]
                
                measurementOutput.x = measurementOutputCorrected.xyh[0]
                measurementOutput.y = measurementOutputCorrected.xyh[1]
                updateHeading = measurementOutputCorrected.xyh[2]
                
                saveKalmanParam()
            }
        } else {
            // Use Server Result
            self.timeUpdatePosition.x = originalResult[0]
            self.timeUpdatePosition.y = originalResult[1]
            self.timeUpdatePosition.heading = originalResult[2]
            
            measurementOutput.x = originalResult[0]
            measurementOutput.y = originalResult[1]
            updateHeading = originalResult[2]
            
            backKalmanParam()
        }
        
        return measurementOutput
    }
    
    func saveKalmanParam() {
        self.pastKalmanP = self.kalmanP
        self.pastKalmanQ = self.kalmanQ
        self.pastKalmanR = self.kalmanR
        self.pastKalmanK = self.kalmanK

        self.pastHeadingKalmanP = self.headingKalmanP
        self.pastHeadingKalmanQ = self.headingKalmanQ
        self.pastHeadingKalmanR = self.headingKalmanR
        self.pastHeadingKalmanK = self.headingKalmanK
    }
    
    func backKalmanParam() {
        self.kalmanP = self.pastKalmanP
        self.kalmanQ = self.pastKalmanQ
        self.kalmanR = self.pastKalmanR
        self.kalmanK = self.pastKalmanK

        self.headingKalmanP = self.pastHeadingKalmanP
        self.headingKalmanQ = self.pastHeadingKalmanQ
        self.headingKalmanR = self.pastHeadingKalmanR
        self.headingKalmanK = self.pastHeadingKalmanK
    }
    
    func compensateHeading(heading: Double, mode: String) -> Double {
        var headingToReturn: Double = heading
        if (mode == "dr") {
            if (headingToReturn < 0) {
                headingToReturn = headingToReturn + 360
            }
            headingToReturn = headingToReturn - floor(headingToReturn/360)*360
        }
        
        return headingToReturn
    }
    
    func CLDtoSD(json: String) -> String {
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
            var result = SectorDetectionResult()
            result.mobile_time = decoded.mobile_time
            result.sector_name = decoded.sector_name
            result.calculated_time = decoded.calculated_time
            
            if (result.sector_name != "") {
                let encodedData = try! JSONEncoder().encode(result)
                if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                    return encodedResult
                } else {
                    return "Fail"
                }
            }
        }
        return "Fail"
    }
    
    func CLDtoBD(json: String) -> String {
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
            var result = BuildingDetectionResult()
            result.mobile_time = decoded.mobile_time
            result.building_name = decoded.building_name
            result.calculated_time = decoded.calculated_time
            
            if (result.building_name != "") {
                let encodedData = try! JSONEncoder().encode(result)
                if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                    return encodedResult
                } else {
                    return "Fail"
                }
            }
        }
        return "Fail"
    }
    
    func CLEtoFLD(json: String) -> String {
        let decoder = JSONDecoder()

        let jsonString = json

        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLocationEstimationResult.self, from: data) {
            var result = FineLevelDetectionResult()
            
            result.mobile_time = decoded.mobile_time
            result.building_name = decoded.building_name
            result.level_name = decoded.level_name
            result.scc = decoded.scc
            result.scr = decoded.scr
            result.calculated_time = decoded.calculated_time
            
            if (result.building_name != "" && result.level_name != "") {
                let encodedData = try! JSONEncoder().encode(result)
                if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                    return encodedResult
                } else {
                    return "Fail"
                }
            }
        }
        return "Fail"
    }
}
