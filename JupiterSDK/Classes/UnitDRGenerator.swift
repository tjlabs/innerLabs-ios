//
//  UnitDRGenerator.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/05/12.
//

import Foundation
import FirebaseCore
import FirebaseMLCommon
import FirebaseMLModelInterpreter
import TFLTensorFlowLite

public class UnitDRGenerator: NSObject {
    
    public override init() {
        
    }
    
    public var unitMode = String()
    
    public let HF = HeadingFunctions()
    public let unitAttitudeEstimator = UnitAttitudeEstimator()
    public let unitStatusEstimator = UnitStatusEstimator()
    public let pdrDistanceEstimator = PDRDistanceEstimator()
    public let drDistanceEstimator = DRDistanceEstimator()
    
    
    public func setMode(mode: String) {
        unitMode = mode
    }
    
    public func setDRModel() {
        drDistanceEstimator.loadModel()
    }
    
    public func generateDRInfo(sensorData: SensorData) -> UnitDRInfo {
        if (unitMode != MODE_PDR && unitMode != MODE_DR) {
            fatalError("Please check unitMode .. (PDR or DR)")
        }
        
        let currentTime = getCurrentTimeInMilliseconds()
        
        let sensorAtt = sensorData.att
        let curAttitude = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
        
        var unitDistance = UnitDistance()
        
        switch (unitMode) {
        case MODE_PDR:
            unitDistance = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
        case MODE_DR:
            unitDistance = drDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
        default:
            unitDistance = pdrDistanceEstimator.estimateDistanceInfo(time: currentTime, sensorData: sensorData)
        }
        
        let unitStatus = unitStatusEstimator.estimateStatus(Attitude: curAttitude, isIndexChanged: unitDistance.isIndexChanged, unitMode: unitMode)
        if (!unitStatus && unitMode == MODE_PDR) {
            unitDistance.length = 0.7
        }
        
        return UnitDRInfo(index: unitDistance.index, length: unitDistance.length, heading: HF.radian2degree(radian: curAttitude.Yaw), lookingFlag: unitStatus, isIndexChanged: unitDistance.isIndexChanged)
    }
    
    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }
}
