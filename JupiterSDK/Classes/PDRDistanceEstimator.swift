//
//  PDRDistanceEstimator.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/05/12.
//

import Foundation

public class PDRDistanceEstimator: NSObject {
    
    public override init() {
        
    }
    
    public var CF = CalculateFunctions()
    public var HF = HeadingFunctions()
    public var PDF = PacingDetectFunctions()
    
    public var peakValleyDetector = PeakValleyDetector()
    public var stepLengthEstimator = StepLengthEstimator()
    public var preAccNormEMA: Double = 0
    public var accNormEMAQueue = LinkedList<TimestampDouble>()
    public var finalUnitResult = UnitDistance()
    
    public var accPeakQueue = LinkedList<TimestampDouble>()
    public var accValleyQueue = LinkedList<TimestampDouble>()
    public var stepLengthQueue = LinkedList<StepLengthWithTimestamp>()
    
    public var normalStepLossCheckQueue = LinkedList<Int>()
    public var normalStepCheckCount = -1
    
    public func estimateDistanceInfo(time: Double, sensorData: SensorData) -> UnitDistance {
        let accNorm = CF.l2Normalize(originalVector: sensorData.acc)
//        print("StepLengthEstimator / accNorm :", accNorm)
        
        // EMA를 통해 센서의 노이즈를 줄임
        let accNormEMA = CF.exponentialMovingAverage(preEMA: preAccNormEMA, curValue: accNorm, windowSize: AVG_NORM_ACC_WINDOW)
        preAccNormEMA = accNormEMA
        
        if (accNormEMAQueue.count < ACC_NORM_EMA_QUEUE_SIZE) {
            accNormEMAQueue.append(TimestampDouble(timestamp: time, valuestamp: accNormEMA))
            return UnitDistance()
            
        } else {
            accNormEMAQueue.pop()
            accNormEMAQueue.append(TimestampDouble(timestamp: time, valuestamp: accNormEMA))
        }
        
        let foundAccPV = peakValleyDetector.findPeakValley(smoothedNormAcc: accNormEMAQueue)
        updateAccQueue(pvStruct: foundAccPV)
        
        finalUnitResult.isIndexChanged = false
        
        if (foundAccPV.type == Type.PEAK) {
            normalStepCheckCount = PDF.updateNormalStepCheckCount(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue, normalStepCheckCount: normalStepCheckCount)
            let isLossStep = checkIsLossStep(normalStepCount: normalStepCheckCount)
            
            if (PDF.isNormalStep(normalStepCount: normalStepCheckCount) || finalUnitResult.index <= 2) {
                finalUnitResult.index += 1
                finalUnitResult.isIndexChanged = true
                
                finalUnitResult.length = 0.65
//                finalUnitResult.length = stepLengthEstimator.estStepLength(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue)
//                if (finalUnitResult.length > 0.7) {
//                    finalUnitResult.length = 0.7
//                } else if (finalUnitResult.length < 0.5) {
//                    finalUnitResult.length = 0.5
//                }
                
                updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp(timestamp: foundAccPV.timestamp, stepLength: finalUnitResult.length))
                
                if (isLossStep && finalUnitResult.index > 3) {
                    finalUnitResult.length = 1.8
                }
//                if (PDF.isPacing(queue: stepLengthQueue)) {
//                    finalUnitResult.length = 0.01
//                }
            }
        }
        
        return finalUnitResult
    }
    
    public func updateAccQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (pvStruct.type == Type.PEAK) {
            updateAccPeakQueue(pvStruct: pvStruct)
        } else if (pvStruct.type == Type.VALLEY) {
            updateAccValleyQueue(pvStruct: pvStruct)
        }
    }
    
    public func updateAccPeakQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (accPeakQueue.count >= ACC_PV_QUEUE_SIZE) {
            accPeakQueue.pop()
        }
        accPeakQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }
    
    public func updateAccValleyQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (accValleyQueue.count >= ACC_PV_QUEUE_SIZE) {
            accValleyQueue.pop()
        }
        accValleyQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }
    
    public func updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp) {
        if (stepLengthQueue.count >= STEP_LENGTH_QUEUE_SIZE) {
            stepLengthQueue.pop()
        }
        stepLengthQueue.append(stepLengthWithTimeStamp)
    }
    
    public func checkIsLossStep(normalStepCount: Int) -> Bool {
        if (normalStepLossCheckQueue.count >= NORMAL_STEP_LOSS_CHECK_SIZE) {
            normalStepLossCheckQueue.pop()
        }
        normalStepLossCheckQueue.append(normalStepCount)
        
        return PacingDetectFunctions().checkLossStep(normalStepCountBuffer: normalStepLossCheckQueue)
    }
}
