import Foundation

public class PacingDetectFunctions: NSObject {
    
    public override init() {
        
    }
    
    public func isPacing(queue: LinkedList<StepLengthWithTimestamp>) -> Bool {
        if (queue.count < 5) {
            return false
        }
        var Buffer: [Double] = []
        
        for i in 0..<queue.count {
            let stepLength = queue.node(at: i)!.value.stepLength
            Buffer += stepLength
        }
        
        let diffStepLengthBuffer = calDiffDoubleBuffer(buffer: Buffer)
        let diffStepLengthVariance = calVariance(buffer: diffStepLengthBuffer, bufferMean: diffStepLengthBuffer.average)
        
        return diffStepLengthVariance >= 0.09
    }

    public func calDiffDoubleBuffer(buffer: [Double]) -> [Double] {
        var diffBuffer: [Double] = []
        for i in 1..<buffer.count {
            diffBuffer += buffer[i] - buffer[i-1]
        }
        return diffBuffer
    }
    
    public func calVariance(buffer: [Double], bufferMean: Double) -> Double {
        var bufferSum: Double = 0
        
        for i in 0..<buffer.count {
            bufferSum += pow((Double(buffer[i]) - bufferMean), 2)
        }
        
        return bufferSum / Double(buffer.count - 1)
    }
    
    public func updateNormalStepCheckCount(accPeakQueue: LinkedList<TimestampDouble>, accValleyQueue: LinkedList<TimestampDouble>, normalStepCheckCount: Int) -> Int {
        
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
    
    public func checkLossStep(normalStepCountBuffer: LinkedList<Int>) -> Bool {
        if (normalStepCountBuffer.count < 3) {
            return false
        } else if (normalStepCountBuffer.node(at: 0)!.value == 0 &&
                   normalStepCountBuffer.node(at: 1)!.value == 1 &&
                   normalStepCountBuffer.node(at: 2)!.value == 2) {
            return true
        } else {
            return false
        }
    }
}
