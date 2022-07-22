import Foundation

let RF_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordRF"
let UV_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordUV"

let SD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/SD"
let BD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/BD"
let CLD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLD"
let FLD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/FLD"
let CLE_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLE"
let FLT_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/FLT"

let JUPITER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/jupiter"

struct Input: Codable {
    var user_id: String
    var index: Int
    var length: Double
    var heading: Double
    var pressure: Double
    var looking_flag: Bool
    var ble: [String: Double]
    var mobile_time: Double
    var device_model: String
    var os_version: Int
}

public struct Output: Codable {
    public var x: Double = 0
    public var y: Double = 0
    public var mobile_time: Double = 0
    public var scc: Double = 0
    public var scr: Double = 0
    public var index: Int = 0
    public var absolute_heading: Double = 0
    public var building : String = ""
    public var level : String = ""
    public var phase : Int = 0
    public var calculated_time: Double = 0
}

public struct InitUser: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
}

struct ReceivedForce: Codable {
    var user_id: String
    var mobile_time: Int
    var ble: [String: Double]
    var pressure: Double
}

struct UserVelocity: Codable {
    var user_id: String
    var mobile_time: Int
    var index: Int
    var length: Double
    var heading: Double
    var looking: Bool
}

// Sector Detection
struct SectorDetection: Codable {
    var user_id: String
    var mobile_time: Int
}

public struct SectorDetectionResult: Codable {
    public var mobile_time: Int
    public var sector_name: String
    public var calculated_time: Double
}

// Building Detection
struct BuildingDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct BuildingDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var calculated_time: Double
}

// Coarse Level Detection
struct CoarseLevelDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct CoarseLevelDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var calculated_time: Double
}


// Fine Level Detection
struct FineLevelDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct FineLevelDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var scr: Double
    public var calculated_time: Double
}

// Coarse Location Estimation
struct CoarseLocationEstimation: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct CoarseLocationEstimationResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var scr: Double
    public var x: Int
    public var y: Int
    public var calculated_time: Double
}


// Fine Location Tracking
struct FineLocationTracking: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct FineLocationTrackingResult: Codable {
    public var mobile_time: Int = 0
    public var building_name: String = ""
    public var level_name: String = ""
    public var scc: Double = 0
    public var scr: Double = 0
    public var x: Int = 0
    public var y: Int = 0
    public var absolute_heading: Double = 0
    public var phase: Int = 0
    public var calculated_time: Double = 0
}
