import Foundation
import TensorFlowLite
//import FirebaseMLModelInterpreter

public class DRDistanceEstimator: NSObject {
    
    public override init() {
        
    }
    
    public let CF = CalculateFunctions()
    public let PDF = PacingDetectFunctions()
    
//    public var interpreter: Interpreter!
//    public var interpreter: ModelInterpreter!
//    public var ioOptions = ModelInputOutputOptions()
    public var interpreter: Interpreter!
    public var ioOptions = InterpreterOptions()
    
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
    
    public func loadModel() {
//        let customBundle = Bundle(for: DRDistanceEstimator.self)
//        guard let resourceBundleURL = customBundle.url(forResource: "JupiterSDK", withExtension: "bundle") else { fatalError("JupiterSDK.bundle not found!") }
//        print("resourceBundleURL :",resourceBundleURL)
//        guard let resourceBundle = Bundle(url: resourceBundleURL) else { return }
//        print("resourceBundle :", resourceBundle)
//
//        guard let modelPath = resourceBundle.path(forResource: "dr_model", ofType: "tflite") else { fatalError("Load Model Error") }
//        let localModel = CustomLocalModel(modelPath: modelPath)
//
//        do {
//            try ioOptions.setInputFormat(index: 0, type: .float32, dimensions: [1, 10])
//            try ioOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1, 2])
//        } catch let error as NSError {
//            print("Failed to set input or output format with error: \(error.localizedDescription)")
//        }
//
//        interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        
//        let conditions = ModelDownloadConditions(allowsCellularAccess: false)
//        ModelDownloader.modelDownloader()
//            .getModel(name: "dr_model",
//                      downloadType: .localModelUpdateInBackground,
//                      conditions: conditions) { result in
//                switch (result) {
//                case .success(let customModel):
//                    do {
//                        // Download complete. Depending on your app, you could enable the ML
//                        // feature, or switch from the local model to the remote model, etc.
//
//                        // The CustomModel object contains the local path of the model file,
//                        // which you can use to instantiate a TensorFlow Lite interpreter.
//                        self.interpreter = try Interpreter(modelPath: customModel.path)
//                        print("Custom Model : ", customModel.path)
//                        print("Custom Model : ", self.interpreter)
//                    } catch {
//                        // Error. Bad model file?
//                    }
//                case .failure(let error):
//                    // Download was unsuccessful. Don't enable ML features.
//                    print("Load Model Error : ", error)
//                }
//        }
        
        let customBundle = Bundle(for: DRDistanceEstimator.self)
        guard let resourceBundleURL = customBundle.url(forResource: "JupiterSDK", withExtension: "bundle") else { fatalError("JupiterSDK.bundle not found!") }
        guard let resourceBundle = Bundle(url: resourceBundleURL) else { return }
        
        guard let modelPath = resourceBundle.path(forResource: "dr_model", ofType: "tflite") else { fatalError("Load Model Error") }
        ioOptions.threadCount = 1
        
        do {
            try interpreter = Interpreter(modelPath: modelPath, options: ioOptions)
        } catch let error as NSError {
            print("Failed to initialize interpreter")
        }
        
    }
    
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
        
        let accVar = CF.calSensorAxisVariance(curArray: accQueue, bufferMean: accSmoothing)
        let gyroVar = CF.calSensorAxisVariance(curArray: gyroQueue, bufferMean: gyroSmoothing)
        var magVar = CF.calSensorAxisVariance(curArray: magQueue, bufferMean: magSmoothing)
        
        if (featureExtractionCount == 0) {
            magVar = lastMagQueue
        }

        let accNormalizeConstant: Double = 7
        let gyroNormalizeConstant: Double = 5
        let magNormalizeConstant: Double = 500
        
        let input: [Float32] = [Float(accVar.x/accNormalizeConstant),
                                Float(accVar.y/accNormalizeConstant),
                                Float(accVar.z/accNormalizeConstant),
                                Float(accVar.norm/accNormalizeConstant),
                                Float(gyroVar.x/gyroNormalizeConstant),
                                Float(gyroVar.y/gyroNormalizeConstant),
                                Float(gyroVar.z/gyroNormalizeConstant),
                                Float(magVar.x/magNormalizeConstant),
                                Float(magVar.y/magNormalizeConstant),
                                Float(magVar.z/magNormalizeConstant)]
        
//        let inputs = ModelInputs()
        var inputData = Data()
        
        for i in 0..<input.count {
            var value = input[i]
            let elementSize = MemoryLayout.size(ofValue: value)
            var bytes = [UInt8](repeating: 0, count: elementSize)
            memcpy(&bytes, &value, elementSize)
            inputData.append(&bytes, count: elementSize)
        }
        
        finalUnitResult.isIndexChanged = false
        
        if (mlpEpochCount == 0) {
            do {
                try interpreter.allocateTensors()
            } catch {
                print("Allocate Error")
            }

            do {
                try interpreter.copy(inputData, toInputAt: 0)
            } catch {
                print("Copy Error")
            }

            do {
                try interpreter.invoke()
            } catch {
                print("Invoke Error")
            }
            
            do {
                let outputTensor = try interpreter.output(at: 0)
                let outputSize = outputTensor.shape.dimensions.reduce(1, {x, y in x*y})
                let outputData = UnsafeMutableBufferPointer<Float32>.allocate(capacity: outputSize)
                outputTensor.data.copyBytes(to: outputData)

                for i in 0..<outputData.count {
                    output[i] = outputData[i]
                }
            } catch {
                print("Output Error")
            }
            
            // ---------- //
//            do {
//                try inputs.addInput(inputData)
//            } catch let error {
//                print("add input failure: \(error)")
//            }
//
//            interpreter.run(inputs: inputs, options: ioOptions) {
//                outputs, error in
//                guard error == nil, let outputs = outputs else {
//                    print("interpreter error")
//                    if (error != nil) {
//                        print(error!)
//                    }
//                    return
//                }
//
//                do {
//                    let result = try outputs.output(index: 0) as! [[NSNumber]]
//                    let floatArray = result[0].map {
//                        a in
//                        a.floatValue
//                    }
//                    // print("Model Result :", floatArray)
//                    self.output = floatArray
//                } catch {
//                    //error
//                }
//            }
            // ------------- //
            
            let argMaxIndex: Int = argmax(array: output)
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
