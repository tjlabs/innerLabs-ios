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
    public var magNormQueue = [Double]()
    public var magNormSmoothingQueue = [Double]()
    public var magNormVarQueue = [Double]()
    public var velocityQueue = [Double]()
    public var mlpOutputQueue = [Int]()
    
    public var mlpEpochCount: Double = 0
    public var featureExtractionCount: Double = 0
    
    public var preNavGyroZSmoothing: Double = 0
    public var preMagNormSmoothing: Double = 0
    public var preMagVarFeature: Double = 0
    public var preVelocitySmoothing: Double = 0
    
    public var distance: Double = 0
    var pastTime: Int = 0
    
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
//        let currentTime = getCurrentTimeInMilliseconds()
//        print("(Time) \(currentTime - self.pastTime)")
//        self.pastTime = currentTime
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
        // ---------------------- Add ---------------------- //
        updateNavGyroZQueue(data: gyroNavZ)
        var navGyroZSmoothing: Double = 0
        if (magNormVarQueue.count == 0) {
            navGyroZSmoothing = gyroNavZ
        } else if (featureExtractionCount < FEATURE_EXTRACTION_SIZE) {
            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: navGyroZQueue.count)
        } else {
            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: Int(FEATURE_EXTRACTION_SIZE))
        }
        preNavGyroZSmoothing = navGyroZSmoothing
        
        updateMagNormQueue(data: magNorm)
        var magNormSmooting: Double = 0
        if (featureExtractionCount == 0) {
            magNormSmooting = magNorm
        } else if (featureExtractionCount < 5) {
            magNormSmooting = CF.exponentialMovingAverage(preEMA: preMagNormSmoothing, curValue: magNorm, windowSize: magNormQueue.count)
        } else {
            magNormSmooting = CF.exponentialMovingAverage(preEMA: preMagNormSmoothing, curValue: magNorm, windowSize: 5)
        }
        preMagNormSmoothing = magNormSmooting
        updateMagNormSmoothingQueue(data: magNormSmooting)

        var magNormVar = PDF.calVariance(buffer: magNormSmoothingQueue, bufferMean: magNormSmoothingQueue.average)
        if (magNormVar > 7) {
            magNormVar = 7
        }
        updateMagNormVarQueue(data: magNormVar)


        var magVarFeature: Double = magNormVar
        if (magNormVarQueue.count == 1) {
            magVarFeature = magNormVar
        } else if (magNormVarQueue.count < Int(SAMPLE_HZ*2)) {
            magVarFeature = CF.exponentialMovingAverage(preEMA: preMagVarFeature, curValue: magNormVar, windowSize: magNormVarQueue.count)
//            let Window: Double = Double(magNormVarQueue.count)
//            let checkA: Double = ((Window - 1)/Window) * preMagVarFeature
//            let checkB: Double = (1/Window) * magNormVar
//            print("Variance // Past : \(preMagVarFeature) // Current : \(magNormVar) // Window : \(Window) // A : \(checkA) // B : \(checkB) // C : \(checkA + checkB)")
        } else {
            magVarFeature = CF.exponentialMovingAverage(preEMA: preMagVarFeature, curValue: magNormVar, windowSize: Int(SAMPLE_HZ*2))
//            let Window: Double = Double(magNormVarQueue.count)
//            let checkA: Double = (Window - 1)/Window * preMagVarFeature
//            let checkB: Double = (1/Window) * magNormVar
//            print("Variance // Past : \(preMagVarFeature) // Current : \(magNormVar) // Window : \(Window) // A : \(checkA) // B : \(checkB) // C : \(checkA + checkB)")
        }
        preMagVarFeature = magVarFeature

        var velocity = log10(magVarFeature+1)/log10(1.1)
        updateVelocityQueue(data: velocity)
//        if velocity < 4 {
//            velocity = 0
//        } else if velocity > 20 {
//            velocity = 20
//        }
        var velocitySmoothing: Double = 0
        if (velocityQueue.count == 1) {
            velocitySmoothing = velocity
        } else if (velocityQueue.count < Int(SAMPLE_HZ)) {
            velocitySmoothing = CF.exponentialMovingAverage(preEMA: preVelocitySmoothing, curValue: velocity, windowSize: velocityQueue.count)
        } else {
            velocitySmoothing = CF.exponentialMovingAverage(preEMA: preVelocitySmoothing, curValue: velocity, windowSize: Int(SAMPLE_HZ))
        }
        preVelocitySmoothing = velocitySmoothing
        
        var velocityInput = velocitySmoothing
        if velocityInput < 4 {
            velocityInput = 0
        } else if velocityInput > 20 {
            velocityInput = 20
        }
        let velocityMps = (velocityInput/3.6)

//        print("Velocity = \(velocityMps*3.6) km/h")
        finalUnitResult.isIndexChanged = false
        finalUnitResult.velocity = velocityMps
        distance += (velocityMps*(1/SAMPLE_HZ))

        if (distance > Double(OUTPUT_DISTANCE_SETTING)) {
            index += 1
            finalUnitResult.length = distance
            finalUnitResult.index = index
            finalUnitResult.isIndexChanged = true

            distance = 0
        }

        featureExtractionCount += 1
        // ---------------------- Add ---------------------- //
        
//        updateMagQueue(data: SensorAxisValue(x: mag[0], y: mag[1], z: mag[2], norm: magNorm))
//        updateNavGyroZQueue(data: gyroNavZ)
//
//        var navGyroZSmoothing: Double = 0
//
//        let lastMagQueue = magQueue.last!.value
//
//        if (magNormVarQueue.count == 0) {
//            navGyroZSmoothing = gyroNavZ
//        } else if (featureExtractionCount < FEATURE_EXTRACTION_SIZE) {
//            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: navGyroZQueue.count)
//        } else {
//            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: Int(FEATURE_EXTRACTION_SIZE))
//        }
//        preNavGyroZSmoothing = navGyroZSmoothing
//
//        // ------ //
//        finalUnitResult.isIndexChanged = false
//        if (mlpEpochCount == 0) {
//
//            var magVar = CF.calSensorAxisVariance(curArray: magQueue)
//            if (featureExtractionCount == 0) {
//                magVar = lastMagQueue
//            }
//
//            let inputMag: [Float32] = [Float(magVar.x), Float(magVar.y), Float(magVar.z), Float(magVar.norm)]
//
//            // Mag //
//            var count = 0
//            var output = 0
//            for i in 0..<inputMag.count {
//                if (inputMag[i] > 0.75) {
//                    count += 1
//                }
//            }
//            if (count >= 1) {
//                output = 1
//            }
//            let argMaxIndex: Int = output
//            // ---------- //
//
//            updateOutputQueue(data: argMaxIndex)
//
//            var moveCount: Int = 0
//            var stopCount: Int = 0
//            for i in 0..<mlpOutputQueue.count {
//                if (mlpOutputQueue[i] == 0) {
//                    stopCount += 1
//                } else {
//                    moveCount += 1
//                }
//            }
//
//            let velocity: Double = Double(moveCount)*VELOCITY_SETTING*exp(-navGyroZSmoothing/1.6)
//
//            finalUnitResult.velocity = velocity
//            distance += (velocity * OUTPUT_SAMPLE_TIME) // * 0.1
//
//            if (distance > Double(OUTPUT_DISTANCE_SETTING)) {
//                index += 1
//                finalUnitResult.length = distance
//                finalUnitResult.index = index
//                finalUnitResult.isIndexChanged = true
//
//                distance = 0
//            }
//        }
//
//        mlpEpochCount += 1
//        featureExtractionCount += 1
//
//        if (mlpEpochCount >= OUTPUT_SAMPLE_EPOCH) {
//            mlpEpochCount = 0
//            output = [0, 0]
//        }
        
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
    
    public func updateMagNormQueue(data: Double) {
        if (magNormQueue.count >= 5) {
            magNormQueue.remove(at: 0)
        }
        magNormQueue.append(data)
    }
    
    public func updateMagNormSmoothingQueue(data: Double) {
        if (magNormSmoothingQueue.count >= Int(SAMPLE_HZ)) {
            magNormSmoothingQueue.remove(at: 0)
        }
        magNormSmoothingQueue.append(data)
    }
    
    public func updateMagNormVarQueue(data: Double) {
        if (magNormVarQueue.count >= Int(SAMPLE_HZ*2)) {
            magNormVarQueue.remove(at: 0)
        }
        magNormVarQueue.append(data)
    }
    
    public func updateVelocityQueue(data: Double) {
        if (velocityQueue.count >= Int(SAMPLE_HZ)) {
            velocityQueue.remove(at: 0)
        }
        velocityQueue.append(data)
    }
    
    func getLocalTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        let nowDate = Date()
        let convertNowStr = dateFormatter.string(from: nowDate)
        
        return convertNowStr
    }
    
    func getCurrentTimeInMilliseconds() -> Int
    {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
}
