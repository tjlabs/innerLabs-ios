import Foundation

public class DRDistanceEstimator: NSObject {
    
    public override init() {
        
    }
    
    public let CF = CalculateFunctions()
    public let HF = HeadingFunctions()
    public let PDF = PacingDetectFunctions()
    
    public var epoch = 0
    public var index = 0
    public var finalUnitResult = UnitDistance()
    public var output: [Float] = [0,0]
    
    public var magQueue = LinkedList<SensorAxisValue>()
    public var navGyroZQueue = [Double]()
    public var mlpOutputQueue = [Int]()
    
    public var mlpEpochCount: Double = 0
    public var featureExtractionCount: Double = 0
    
    public var preNavGyroZSmoothing: Double = 0
    
    public var distance: Double = 0
    
    var preRoll: Double = 0
    var prePitch: Double = 0
    
    public func argmax(array: [Float]) -> Int {
        let output1 = array[0]
        let output2 = array[1]
        
        if (output1 > output2){
            return 0
        } else {
            return 1
        }
    }
    
    public func estimateDistanceInfo(time: Double, sensorData: SensorData) -> UnitDistance{
        // feature extraction
        // ACC X, Y, Z, Norm Smoothing
        // Use y, z, norm variance (2sec)
        
        let acc = sensorData.acc
        let gyro = sensorData.gyro
        let mag = sensorData.mag
        
        var accRoll = HF.callRollUsingAcc(acc: acc)
        var accPitch = HF.callPitchUsingAcc(acc: acc)

        if (accRoll.isNaN) {
            accRoll = preRoll
        } else {
            preRoll = accRoll
        }

        if (accPitch.isNaN) {
            accPitch = prePitch
        } else {
            prePitch = accPitch
        }
        
        let accAttitude = Attitude(Roll: accRoll, Pitch: accPitch, Yaw: 0)
        
        let gyroNavZ = abs(CF.transBody2Nav(att: accAttitude, data: gyro)[2])
        
        let magNorm = CF.l2Normalize(originalVector: sensorData.mag)
        
        updateMagQueue(data: SensorAxisValue(x: mag[0], y: mag[1], z: mag[2], norm: magNorm))
        updateNavGyroZQueue(data: gyroNavZ)
        
        var navGyroZSmoothing: Double = 0
        
        let lastMagQueue = magQueue.last!.value
        
        if (featureExtractionCount == 0) {
            navGyroZSmoothing = gyroNavZ
        } else if (featureExtractionCount < FEATURE_EXTRACTION_SIZE) {
            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: navGyroZQueue.count)
        } else {
            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: Int(FEATURE_EXTRACTION_SIZE))
        }
        
        preNavGyroZSmoothing = navGyroZSmoothing
        
        // ------ //
        finalUnitResult.isIndexChanged = false
        if (mlpEpochCount == 0) {
            
            var magVar = CF.calSensorAxisVariance(curArray: magQueue)
            if (featureExtractionCount == 0) {
                magVar = lastMagQueue
            }
            
            let inputMag: [Float32] = [Float(magVar.x), Float(magVar.y), Float(magVar.z), Float(magVar.norm)]
            
            // Mag //
            var count = 0
            var output = 0
            for i in 0..<inputMag.count {
                if (inputMag[i] > 0.6) {
                    count += 1
                }
            }
            if (count >= 2) {
                output = 1
            }
            let argMaxIndex: Int = output
            // ---------- //
            
            updateOutputQueue(data: argMaxIndex)
            
            var moveCount: Int = 0
            var stopCount: Int = 0
            for i in 0..<mlpOutputQueue.count {
                if (mlpOutputQueue[i] == 0) {
                    stopCount += 1
                } else {
                    moveCount += 1
                }
            }
            
            let velocity: Double = Double(moveCount)*VELOCITY_SETTING*exp(-navGyroZSmoothing/1.7)
            
            finalUnitResult.velocity = velocity
            distance += (velocity * OUTPUT_SAMPLE_TIME) // * 0.1
            
            if (distance > Double(OUTPUT_DISTANCE_SETTING)) {
                index += 1
                finalUnitResult.length = distance
                finalUnitResult.index = index
                finalUnitResult.isIndexChanged = true
                
                distance = 0
            }
        }
        
        mlpEpochCount += 1
        featureExtractionCount += 1
        
        
        if (mlpEpochCount >= OUTPUT_SAMPLE_EPOCH) {
            mlpEpochCount = 0
            output = [0, 0]
        }
        
        return finalUnitResult
    }
    
    public func updateMagQueue(data: SensorAxisValue) {
        if (magQueue.count >= Int(FEATURE_EXTRACTION_SIZE)) {
            magQueue.pop()
        }
        magQueue.append(data)
    }
    
    public func updateNavGyroZQueue(data: Double) {
        if (navGyroZQueue.count >= Int(FEATURE_EXTRACTION_SIZE)) {
            navGyroZQueue.remove(at: 0)
        }
        navGyroZQueue.append(data)
    }
    
    public func updateOutputQueue(data: Int) {
        if (mlpOutputQueue.count >= Int(VELOCITY_QUEUE_SIZE)) {
            mlpOutputQueue.remove(at: 0)
        }
        mlpOutputQueue.append(data)
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
