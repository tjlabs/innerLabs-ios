import Foundation

struct UserInfo: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
}

struct CardList: Codable {
    var sectors: [CardInfo]
}

struct CardInfo: Codable {
    var sector_id: Int
    var sector_name: String
    var description: String
    var card_color: String
    var dead_reckoning: String
    var service_request: String
    var building_level: [[String]]
}

public struct Attitude: Equatable {
    public var Roll: Double = 0
    public var Pitch: Double = 0
    public var Yaw: Double = 0
}

public struct StepResult: Equatable {
    public var count: Double = 0
    public var heading: Double = 0
    public var pressure: Double = 0
    public var stepLength: Double = 0
    public var isLooking: Bool = true
}

public struct UnitDistance: Equatable {
    public var index: Int = 0
    public var length: Double = 0
    public var velocity: Double = 0
    public var isIndexChanged: Bool = false
}


public struct TimestampDouble: Equatable {
    public var timestamp: Double = 0
    public var valuestamp: Double = 0
}


public struct StepLengthWithTimestamp: Equatable {
    public var timestamp: Double = 0
    public var stepLength: Double = 0

}

public struct SensorAxisValue: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var z: Double = 0
    
    public var norm: Double = 0
}

public struct KalmanOutput: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var heading: Double = 0
    
    public func toString() -> String {
        return "{x : \(x), y : \(y), search_direction : \(heading)}"
    }
}

public struct UnitDRInfo {
    public var index: Int = 0
    public var length: Double = 0
    public var heading: Double = 0
    public var velocity: Double = 0
    public var lookingFlag: Bool = false
    public var isIndexChanged: Bool = false
    
    public func toString() -> String {
        return "{index : \(index), length : \(length), heading : \(heading), velocity : \(velocity), lookingFlag : \(lookingFlag), isStepDetected : \(isIndexChanged)}"
    }
}

public struct ServiceResult {
    public var isIndexChanged: Bool = false
    
    public var indexTx: Int = 0
    public var indexRx: Int = 0
    public var length: Double = 0
    public var velocity: Double = 0
    public var heading: Double = 0
    public var scc: Double = 0
    public var phase: String = ""
    
    public var level: String = ""
    public var building: String = ""
}

// ------------------------------------------------- //
// -------------------- Network -------------------- //
// ------------------------------------------------- //

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
    
    public init() {
        self.mobile_time = 0
        self.sector_name = ""
        self.calculated_time = 0
    }
}

// Building Detection
struct BuildingDetection: Codable {
    var user_id: String
    var mobile_time: Int
}

public struct BuildingDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.calculated_time = 0
    }
}

// Coarse Level Detection
struct CoarseLevelDetection: Codable {
    var user_id: String
    var mobile_time: Int
}

public struct CoarseLevelDetectionResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var calculated_time: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.calculated_time = 0
    }
}


// Fine Level Detection
struct FineLevelDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct FineLevelDetectionResult: Codable {
    public var mobile_time: Int = 0
    public var building_name: String = ""
    public var level_name: String = ""
    public var scc: Double = 0
    public var scr: Double = 0
    public var calculated_time: Double = 0
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.scr = 0
        self.calculated_time = 0
    }
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
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.scr = 0
        self.x = 0
        self.y = 0
        self.calculated_time = 0
    }
}


// Fine Location Tracking
struct FineLocationTracking: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
    var phase: Int
}

public struct FineLocationTrackingFromServer: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var scr: Double
    public var x: Double
    public var y: Double
    public var absolute_heading: Double
    public var phase: Int
    public var calculated_time: Double
    public var index: Int
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.scr = 0
        self.x = 0
        self.y = 0
        self.absolute_heading = 0
        self.phase = 0
        self.calculated_time = 0
        self.index = 0
    }
}

public struct FineLocationTrackingResult: Codable {
    public var mobile_time: Int
    public var building_name: String
    public var level_name: String
    public var scc: Double
    public var scr: Double
    public var x: Double
    public var y: Double
    public var absolute_heading: Double
    public var phase: Int
    public var calculated_time: Double
    public var index: Int
    public var velocity: Double
    
    public init() {
        self.mobile_time = 0
        self.building_name = ""
        self.level_name = ""
        self.scc = 0
        self.scr = 0
        self.x = 0
        self.y = 0
        self.absolute_heading = 0
        self.phase = 0
        self.calculated_time = 0
        self.index = 0
        self.velocity = 0
    }
}
