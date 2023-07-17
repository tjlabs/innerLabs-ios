import Foundation


public class ReceivedForceSurfaceCorrelator {
    
    let D = 15*2 // 15s
    let T = 5*2 // 5s
    
    var rfdBufferLength = 40
    var rfdBuffer = [[String: Double]]()
    
    init() {
        self.rfdBufferLength = (self.D + self.T)
    }
    
    public func accumulateRfdBuffer(bleData: [String: Double]) -> Bool {
        var isSufficient: Bool = false
        if (self.rfdBuffer.count < self.rfdBufferLength) {
            if (self.rfdBuffer.isEmpty) {
                self.rfdBuffer.append(["empty": -100.0])
            } else {
                self.rfdBuffer.append(bleData)
            }
        } else {
            isSufficient = true
            self.rfdBuffer.remove(at: 0)
            if (self.rfdBuffer.isEmpty) {
                self.rfdBuffer.append(["empty": -100.0])
            } else {
                self.rfdBuffer.append(bleData)
            }
        }
        
        return isSufficient
    }
    
    public func getRfdScc() -> Double {
        var result: Double = 0
        
        if (self.rfdBuffer.count >= self.rfdBufferLength) {
            let preRfdBuffer = sliceDictionaryArray(self.rfdBuffer, startIndex: 0, endIndex: D-1)
            let curRfdBuffer = sliceDictionaryArray(self.rfdBuffer, startIndex: T, endIndex: self.rfdBufferLength-1)
//            print("(RFC) // preRfdBuffer = \(preRfdBuffer.count)")
//            print("(RFC) // curRfdBuffer = \(curRfdBuffer.count)")
            
            var sumDiffRssiArray = [Double]()
            for i in 0..<D {
                let preRfd = preRfdBuffer[i]
                let curRfd = curRfdBuffer[i]
                
                var sumDiffRssi: Double = 0
                for (key, value) in curRfd {
                    let curRssi = value
                    let preRssi = preRfd[key] ?? -100.0
                    
                    sumDiffRssi += abs(curRssi - preRssi)
//                    print("(RFC) // sumDiffRssi = \(sumDiffRssi) , curRssi = \(curRssi) , preRssi = \(preRssi)")
                }
                sumDiffRssiArray.append(sumDiffRssi/Double(curRfd.keys.count))
            }
            
            if (!sumDiffRssiArray.isEmpty) {
//                print("(RFC) // sumDiffRssiArray = \(sumDiffRssiArray) , count = \(sumDiffRssiArray.count)")
//                print("(RFC) // sumDiffRssiArrayMean = \(sumDiffRssiArray.average)")
                result = calcScc(value: sumDiffRssiArray.average)
            }
        }
        
        return result
    }
    
    func calcScc(value: Double) -> Double {
        return exp(-value/10)
    }
    
    func sliceDictionaryArray(_ array: [[String: Double]], startIndex: Int, endIndex: Int) -> [[String: Double]] {
        let arrayCount = array.count
        
        guard startIndex >= 0 && startIndex < arrayCount && endIndex >= 0 && endIndex < arrayCount else {
            return []
        }
        
        var slicedArray: [[String: Double]] = []
        for index in startIndex...endIndex {
            slicedArray.append(array[index])
        }
        
        return slicedArray
    }
}
