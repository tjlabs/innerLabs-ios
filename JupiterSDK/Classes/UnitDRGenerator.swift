import Foundation

public class UnitDRGenerator: NSObject {
    
    public override init() {
        
    }
    
    public var unitMode = String()
    
    public let CF = CalculateFunctions()
    public let HF = HeadingFunctions()
    public let unitAttitudeEstimator = UnitAttitudeEstimator()
    public let unitStatusEstimator = UnitStatusEstimator()
    public let pdrDistanceEstimator = PDRDistanceEstimator()
    public let drDistanceEstimator = DRDistanceEstimator()
    
    public func setMode(mode: String) {
        unitMode = mode
    }
    
    public func generateDRInfo(sensorData: SensorData) -> UnitDRInfo {
        if (unitMode != MODE_PDR && unitMode != MODE_DR && unitMode != MODE_AUTO) {
            fatalError("Please check unitMode .. (pdr, dr, auto)")
        }
        
        let currentTime = getCurrentTimeInMilliseconds()
        var curAttitudeDr = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
        var curAttitudePdr = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
        
        var unitDistanceDr = UnitDistance()
        var unitDistancePdr = UnitDistance()
        
        switch (unitMode) {
        case MODE_PDR:
            unitDistancePdr = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            let sensorAtt = sensorData.att
            curAttitudePdr = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudePdr, isIndexChanged: unitDistancePdr.isIndexChanged, unitMode: unitMode)
            if (!unitStatus && unitMode == MODE_PDR) {
                unitDistancePdr.length = 0.7
            }
            
            let heading = HF.radian2degree(radian: curAttitudePdr.Yaw)
            
            return UnitDRInfo(index: unitDistancePdr.index, length: unitDistancePdr.length, heading: heading, velocity: unitDistancePdr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistancePdr.isIndexChanged)
        case MODE_DR:
            unitDistanceDr = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let heading = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: unitMode)
            return UnitDRInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, heading: heading, velocity: unitDistanceDr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistanceDr.isIndexChanged)
        case MODE_AUTO:
            unitDistanceDr = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            unitDistancePdr = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            let sensorAtt = sensorData.att
            curAttitudePdr = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let heading = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatusPdr = unitStatusEstimator.estimateStatus(Attitude: curAttitudePdr, isIndexChanged: unitDistancePdr.isIndexChanged, unitMode: MODE_PDR)
            let unitStatusDr = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: MODE_DR)
            
            return UnitDRInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, heading: heading, velocity: unitDistanceDr.velocity, lookingFlag: unitStatusDr, isIndexChanged: unitDistanceDr.isIndexChanged)
        default:
            unitDistancePdr = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            let sensorAtt = sensorData.att
            curAttitudePdr = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudePdr, isIndexChanged: unitDistancePdr.isIndexChanged, unitMode: unitMode)
            if (!unitStatus && unitMode == MODE_PDR) {
                unitDistancePdr.length = 0.7
            }
            
            let heading = HF.radian2degree(radian: curAttitudePdr.Yaw)
            
            return UnitDRInfo(index: unitDistancePdr.index, length: unitDistancePdr.length, heading: heading, velocity: unitDistancePdr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistancePdr.isIndexChanged)
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}
