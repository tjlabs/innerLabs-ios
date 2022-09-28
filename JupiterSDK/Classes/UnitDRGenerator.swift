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
        if (unitMode != MODE_PDR && unitMode != MODE_DR) {
            fatalError("Please check unitMode .. (pdr or dr)")
        }
        
        let currentTime = getCurrentTimeInMilliseconds()
        var curAttitude = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
        
        var unitDistance = UnitDistance()
        
        switch (unitMode) {
        case MODE_PDR:
            unitDistance = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            let sensorAtt = sensorData.att
            curAttitude = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
//            curAttitude = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
        case MODE_DR:
            unitDistance = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            curAttitude = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
        default:
            unitDistance = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            
            let sensorAtt = sensorData.att
            curAttitude = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
        }
        
        let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitude, isIndexChanged: unitDistance.isIndexChanged, unitMode: unitMode)
        if (!unitStatus && unitMode == MODE_PDR) {
            unitDistance.length = 0.7
        }
        
        let heading = HF.radian2degree(radian: curAttitude.Yaw)
        
        return UnitDRInfo(index: unitDistance.index, length: unitDistance.length, heading: heading, velocity: unitDistance.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistance.isIndexChanged)
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}
