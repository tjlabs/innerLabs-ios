//
//  TjAlgorithm.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

let AVG_NORM_ACC_WINDOW = 20
let AVG_ATTITUDE_WINDOW = 20
let SAMPLE_HZ = 40
let ACC_PV_QUEUE_SIZE = 3
let ACC_NORM_EMA_QUEUE_SIZE = 3
let STEP_LENGTH_QUEUE_SIZE = 5
let NORMAL_STEP_LOSS_CHECK_SIZE = 3
let LOOKING_FLAG_STEP_CHECK_SIZE = 3

public class TjAlgorithm: NSObject {
    public override init() {
        
    }
    
    public var timeBefore: Double = 0.0
    public var peakValleyDetector = PeakValleyDetector()
    public var stepLengthEstimator = StepLengthEstimator()
    public var preAccNormEMA = 0
    public var preGameVecAttEMA = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
    public var accNormEMAQueue = LinkedList<TimestampFloat>()
    public var finalStepResult = Step()
    
    public var headingGyroGame: Float = 0
    
    public var accPeakQueue = LinkedList<TimestampFloat>()
    public var accValleyQueue = LinkedList<TimestampFloat>()
    public var stepLengthQueue = LinkedList<StepLengthWithTimestamp>()

    public var normalStepLossCheckQueue = LinkedList<Int>()
    public var lookingFlagStepQueue = LinkedList<Bool>()
    
    public var normalStepCheckCount = -1
    
//    public func runAlgorithm(sensorData: SensorData) -> Step {
//
//    }
    
    public func updateAccQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (pvStruct.type == Type.PEAK) {
            updateAccPeakQueue(pvStruct: pvStruct)
        } else if (pvStruct.type == Type.VALLEY) {
            updateAccValleyQueue(pvStruct: pvStruct)
        }
    }
    
    public func updateAccPeakQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (accPeakQueue.count >= ACC_PV_QUEUE_SIZE) {
            accPeakQueue.remove(at: 0)
        }
        accPeakQueue.add(Node(value: TimestampFloat(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue)))
    }
    
    public func updateAccValleyQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (accValleyQueue.count >= ACC_PV_QUEUE_SIZE) {
            accValleyQueue.remove(at: 0)
        }
        
        accValleyQueue.add(Node(value: TimestampFloat(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue)))
    }
    
    public func updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp) {
        if (stepLengthQueue.count >= STEP_LENGTH_QUEUE_SIZE) {
            stepLengthQueue.remove(at: 0)
        }
        
        stepLengthQueue.add(Node(value:stepLengthWithTimeStamp))
    }
    
    public func checkIsLossStep(normalStepCount: Int) -> Bool {
        if (normalStepLossCheckQueue.count >= NORMAL_STEP_LOSS_CHECK_SIZE) {
            normalStepLossCheckQueue.remove(at: 0)
        }
        normalStepLossCheckQueue.add(Node(value:normalStepCount))

        return PacingDetectFunctions().checkLossStep(normalStepCountBuffer: normalStepLossCheckQueue)
    }
    
    public func checkLookingAttitude(lookingFlagStepQueue: LinkedList<Bool>) -> Bool {
        if (lookingFlagStepQueue.count <= 2) {
            return true
        } else {
            var bufferSum = 0
            for i in 0...lookingFlagStepQueue.count {
                let value = lookingFlagStepQueue.node(at: i)!.value
                if (value) { bufferSum += 1 }
            }
            
            if (bufferSum >= 2) {
                return true
            } else {
                return false
            }
        }
    }
}
