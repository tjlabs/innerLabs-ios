import Foundation

public class UnitDRGenerator: NSObject {
    
    public override init() {
        
    }
    
    let STEP_TO_MODE_CHANGE = 5
    var STEP_VALID_TIME: Double = 1000
    var validStepCount = 0
    
    public var unitMode = String()
    
    public let CF = CalculateFunctions()
    public let HF = HeadingFunctions()
    public let unitAttitudeEstimator = UnitAttitudeEstimator()
    public let unitStatusEstimator = UnitStatusEstimator()
    public let pdrDistanceEstimator = PDRDistanceEstimator()
    public let drDistanceEstimator = DRDistanceEstimator()
    
    var pdrQueue = LinkedList<DistanceInfo>()
    var drQueue = LinkedList<DistanceInfo>()
    
    var preRoll: Double = 0
    var prePitch: Double = 0
    
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
            
            var sensorAtt = sensorData.att
            
            if (sensorAtt[0].isNaN) {
                sensorAtt[0] = preRoll
            } else {
                preRoll = sensorAtt[0]
            }

            if (sensorAtt[1].isNaN) {
                sensorAtt[1] = prePitch
            } else {
                prePitch = sensorAtt[1]
            }
            
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
            
            updateDrQueue(data: DistanceInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, time: currentTime, isIndexChanged: unitDistanceDr.isIndexChanged))
            updatePdrQueue(data: DistanceInfo(index: unitDistancePdr.index, length: unitDistancePdr.length, time: currentTime, isIndexChanged: unitDistancePdr.isIndexChanged))
            
            checkModeChange()
            
            let sensorAtt = sensorData.att
            curAttitudePdr = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let heading = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatusPdr = unitStatusEstimator.estimateStatus(Attitude: curAttitudePdr, isIndexChanged: unitDistancePdr.isIndexChanged, unitMode: MODE_PDR)
            let unitStatusDr = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: MODE_DR)
            
            return UnitDRInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, heading: heading, velocity: unitDistanceDr.velocity, lookingFlag: unitStatusDr, isIndexChanged: unitDistanceDr.isIndexChanged)
        default:
            // (Default : DR Mode)
            unitDistanceDr = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
            curAttitudeDr = unitAttitudeEstimator.estimateAtt(time: currentTime, acc: sensorData.acc, gyro: sensorData.gyro, rotMatrix: sensorData.rotationMatrix)
            
            let heading = HF.radian2degree(radian: curAttitudeDr.Yaw)
            
            let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitudeDr, isIndexChanged: unitDistanceDr.isIndexChanged, unitMode: unitMode)
            return UnitDRInfo(index: unitDistanceDr.index, length: unitDistanceDr.length, heading: heading, velocity: unitDistanceDr.velocity, lookingFlag: unitStatus, isIndexChanged: unitDistanceDr.isIndexChanged)
        }
    }
    
    func checkModeChange() {
        let drQueueLen = drQueue.count
        let pdrQueueLen = pdrQueue.count
        
        // 최근 N개의 PDR 스텝이 연속적으로 발생하는지 확인
        if (pdrQueueLen > STEP_TO_MODE_CHANGE) {
            for i in (pdrQueueLen-STEP_TO_MODE_CHANGE)..<pdrQueueLen {
                let pdrCurrent = pdrQueue.node(at: i)!.value
                let pdrBefore = pdrQueue.node(at: i-1)!.value
                
                let timeDiff = pdrCurrent.time - pdrBefore.time
                
                if timeDiff < STEP_VALID_TIME {
                    self.validStepCount += 1
                }
            }
        }
        
        if (self.validStepCount > STEP_TO_MODE_CHANGE) {
            // 현재 모드는 PDR
            self.validStepCount = 0
        }
        
        // DR 상황에서는 스텝이 연속적으로 발생하지 않음
        
        // PDR 스텝이 연속적으로 발생하면
        
        // PDR 스텝이 아주 가끔
        
//        print(getLocalTimeString() + " (Jupiter) DR Queue: \(drQueue)")
//        print(getLocalTimeString() + " (Jupiter) PDR Queue: \(pdrQueue)")
    }
    
    public func updateDrQueue(data: DistanceInfo) {
        if (drQueue.count >= Int(MODE_QUEUE_SIZE)) {
            drQueue.pop()
        }
        drQueue.append(data)
    }
    
    public func updatePdrQueue(data: DistanceInfo) {
        if (pdrQueue.count >= Int(MODE_QUEUE_SIZE)) {
            pdrQueue.pop()
        }
        pdrQueue.append(data)
    }
    
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
    }
}
