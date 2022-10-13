import Foundation

public class DRDistanceEstimator: NSObject {
    
    public override init() {
        
    }
    
    public let CF = CalculateFunctions()
    public let PDF = PacingDetectFunctions()
    
    public var epoch = 0
    public var index = 0
    public var finalUnitResult = UnitDistance()
    public var output: [Float] = [0,0]
    
    public var accQueue = LinkedList<SensorAxisValue>()
    public var gyroQueue = LinkedList<SensorAxisValue>()
    public var magQueue = LinkedList<SensorAxisValue>()
    public var navGyroZQueue = [Double]()
    public var mlpOutputQueue = [Int]()
    
    public var mlpEpochCount: Double = 0
    public var featureExtractionCount: Double = 0
    
    public var preAccSmoothing = SensorAxisValue()
    public var preGyroSmoothing = SensorAxisValue()
    public var preMagSmoothing = SensorAxisValue()
    public var preNavGyroZSmoothing: Double = 0
    
    public var distance: Double = 0
    var preInputMag: [Float32] = [0, 0, 0]
    var preMagNorm: Double = 0
    
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
        
        let att = Attitude(Roll: sensorData.att[0], Pitch: sensorData.att[1], Yaw: sensorData.att[2])
        
        let gyroNavZ = abs(CF.transBody2Nav(att: att, data: gyro)[2])
        
        let accNorm = CF.l2Normalize(originalVector: sensorData.acc)
        let magNorm = CF.l2Normalize(originalVector: sensorData.mag)
        
        updateAccQueue(data: SensorAxisValue(x: acc[0], y: acc[1], z: acc[2], norm: accNorm))
        updateGyroQueue(data: SensorAxisValue(x: gyro[0], y: gyro[1], z: gyro[2], norm: 0))
        updateMagQueue(data: SensorAxisValue(x: mag[0], y: mag[1], z: mag[2], norm: 0))
        updateNavGyroZQueue(data: gyroNavZ)
        
        var accSmoothing = SensorAxisValue()
        var gyroSmoothing = SensorAxisValue()
        var magSmoothing = SensorAxisValue()
        var navGyroZSmoothing: Double = 0
        
        let lastAccQueue = accQueue.last!.value
        let lastGyroQueue = gyroQueue.last!.value
        let lastMagQueue = magQueue.last!.value
        
        if (featureExtractionCount == 0) {
            accSmoothing = SensorAxisValue(x: acc[0], y: acc[1], z: acc[2], norm: accNorm)
            gyroSmoothing = SensorAxisValue(x: gyro[0], y: gyro[1], z: gyro[2], norm: 0)
            magSmoothing = SensorAxisValue(x: mag[0], y: mag[1], z: mag[2], norm: 0)
            navGyroZSmoothing = gyroNavZ
        } else if (featureExtractionCount < FEATURE_EXTRATION_SIZE) {
            accSmoothing = CF.calSensorAxisEMA(preArrayEMA: preAccSmoothing, curArray: lastAccQueue, windowSize: accQueue.count)
            gyroSmoothing = CF.calSensorAxisEMA(preArrayEMA: preGyroSmoothing, curArray: lastGyroQueue, windowSize: gyroQueue.count)
            magSmoothing = CF.calSensorAxisEMA(preArrayEMA: preMagSmoothing, curArray: lastMagQueue, windowSize: magQueue.count)
            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: navGyroZQueue.count)
        } else {
            accSmoothing = CF.calSensorAxisEMA(preArrayEMA: preAccSmoothing, curArray: lastAccQueue, windowSize: Int(FEATURE_EXTRATION_SIZE))
            gyroSmoothing = CF.calSensorAxisEMA(preArrayEMA: preGyroSmoothing, curArray: lastGyroQueue, windowSize: Int(FEATURE_EXTRATION_SIZE))
            magSmoothing = CF.calSensorAxisEMA(preArrayEMA: preMagSmoothing, curArray: lastMagQueue, windowSize: Int(FEATURE_EXTRATION_SIZE))
            navGyroZSmoothing = CF.exponentialMovingAverage(preEMA: preNavGyroZSmoothing, curValue: gyroNavZ, windowSize: Int(FEATURE_EXTRATION_SIZE))
        }
        
        preAccSmoothing = accSmoothing
        preGyroSmoothing = gyroSmoothing
        preMagSmoothing = magSmoothing
        preNavGyroZSmoothing = navGyroZSmoothing
        
        var magVar = CF.calSensorAxisVariance(curArray: magQueue, bufferMean: magSmoothing)
        
        if (featureExtractionCount == 0) {
            magVar = lastMagQueue
        }
        
        let inputMag: [Float32] = [Float(0.1*(magVar.x)) + 0.9*preInputMag[0],
                                   Float(0.1*(magVar.y)) + 0.9*preInputMag[1],
                                   Float(0.1*(magVar.z)) + 0.9*preInputMag[2],
                                   Float(0.1*magNorm + 0.9*preMagNorm)]
        // ------ //
        finalUnitResult.isIndexChanged = false
        
        if (mlpEpochCount == 0) {
            // Mag //
            var count = 0
            var output = 0
            for i in 0..<inputMag.count {
                
                if (inputMag[i] > 0.7) {
                    count += 1
                }
            }
            if (count >= 2) {
                output = 1
            }
            let argMaxIndex: Int = output
            // ---------- //
            
            updateOutputQueue(data: argMaxIndex)
            
            var outputSum: Int = 0
            for i in 0..<mlpOutputQueue.count {
                outputSum += mlpOutputQueue[i]
            }
            
            let velocity: Double = Double(outputSum) * VELOCITY_SETTING * exp(-navGyroZSmoothing/1.5)
            finalUnitResult.velocity = velocity
            distance += (velocity * OUTPUT_SAMPLE_TIME)
            
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
        
        // Mag
        preInputMag = inputMag
        preMagNorm = magNorm
        
        if (mlpEpochCount == OUTPUT_SAMPLE_EPOCH) {
            mlpEpochCount = 0
            output = [0, 0]
        }
        
        return finalUnitResult
    }
    
    
    public func updateAccQueue(data: SensorAxisValue) {
        if (accQueue.count >= Int(FEATURE_EXTRATION_SIZE)) {
            accQueue.pop()
        }
        accQueue.append(data)
    }
    
    public func updateGyroQueue(data: SensorAxisValue) {
        if (gyroQueue.count >= Int(FEATURE_EXTRATION_SIZE)) {
            gyroQueue.pop()
        }
        gyroQueue.append(data)
    }
    
    public func updateMagQueue(data: SensorAxisValue) {
        if (magQueue.count >= Int(FEATURE_EXTRATION_SIZE)) {
            magQueue.pop()
        }
        magQueue.append(data)
    }
    
    public func updateNavGyroZQueue(data: Double) {
        if (navGyroZQueue.count >= Int(FEATURE_EXTRATION_SIZE)) {
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
}
