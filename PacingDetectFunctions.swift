//
//  PacingDetectFunctions.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

public class PacingDetectFunctions: NSObject {
    
    public override init() {
        
    }
    
    public func isPacing(queue: LinkedList<StepLengthWithTimestamp>) -> Bool {
        if (queue.count < 5) {
            return false
        }
//        var diffStepLengthBuffer = callDif
        return false
    }
//
    public func calDiffFloatBuffer(buffer: [Float]) -> [Float] {
        var diffBuffer: [Float] = []
        for i in 1...buffer.count {
            diffBuffer += buffer[i] - buffer[i-1]
        }
        return diffBuffer
    }
    
    public func calVariance(buffer: [Float]) -> Double {
        var bufferSum: Double = 0
        let bufferMean = buffer.average
        for i in 0...buffer.count {
            bufferSum += pow((Double(buffer[i]) - bufferMean), 2)
        }
        
        return bufferSum / Double(buffer.count - 1)
    }
    
    public func updateNormalStepCheckCount(accPeakQueue: LinkedList<TimestampFloat>, accValleyQueue: LinkedList<TimestampFloat>, normalStepCheckCount: Int) -> Int {
        
        if (accPeakQueue.count <= 2 || accValleyQueue.count <= 2) {
            return normalStepCheckCount + 1
        }
        
        guard let condition1 = accPeakQueue.last?.value.timestamp else { return 0 }
        guard let condition2 = accPeakQueue.node(at: accPeakQueue.count-2)?.value.timestamp else { return 0 }
        guard let condition3 = accPeakQueue.last?.value.valuestamp else { return 0 }
        guard let condition4 = accPeakQueue.node(at: accPeakQueue.count-2)?.value.valuestamp else { return 0 }
        
        if (condition1 - condition2 < 2000 && abs(condition3 - condition4) < 1) {
            return normalStepCheckCount + 1
        }
        
        return 0
    }
    
    public func isNormalStep(normalStepCount: Int) -> Bool {
        return normalStepCount >= 2
    }
    
//    public func checkLossStep(normalStepCountBuffer: [Int]) -> Bool {
//        return if (normalStepCountBuffer.count < 3) {
//            false
//        } else {
//            normalStepCountBuffer ==
//        }
//    }
}
