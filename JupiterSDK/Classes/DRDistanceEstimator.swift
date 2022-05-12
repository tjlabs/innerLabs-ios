//
//  DRDistanceEstimator.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/05/12.
//

import Foundation
import FirebaseCore
import FirebaseMLCommon
import FirebaseMLModelInterpreter
import TFLTensorFlowLite

let SAMPLE_HZ_INT = 40
let SEND_INTERVAL_SECOND = 1
let OUTPUT_SAMPLE_TIME = SAMPLE_HZ_INT * SEND_INTERVAL_SECOND
let FEATURE_EXTRATION_SIZE = SAMPLE_HZ_INT * 2

public class DRDistanceEstimator: NSObject {
    
    public override init() {
        
    }
    
    public let CF = CalculateFunctions()
    public let PDF = PacingDetectFunctions()
    
    public var interpreter: ModelInterpreter!
    public var ioOptions = ModelInputOutputOptions()
    
    public var epoch = 0
    public var index = 0
    public var finalUnitResult = UnitDistance()
    public var output: [Float32] = [0,0,0]
    public var accYQue = [Double]()
    public var accZQue = [Double]()
    public var accNormQue = [Double]()
    
    public func loadModel() {
        let customBundle = Bundle(for: DRDistanceEstimator.self)
        guard let resourceBundleURL = customBundle.url(forResource: "JupiterSDK", withExtension: "bundle") else { fatalError("JupiterSDK.bundle not found!") }
        print("resourceBundleURL :",resourceBundleURL)
        guard let resourceBundle = Bundle(url: resourceBundleURL) else { return }
        print("resourceBundle :", resourceBundle)
        
        guard let modelPath = resourceBundle.path(forResource: "dr_model", ofType: "tflite") else { fatalError("Load Model Error") }
        let localModel = CustomLocalModel(modelPath: modelPath)
        
        do {
            try ioOptions.setInputFormat(index: 0, type: .float32, dimensions: [1, 3])
            try ioOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1, 3])
        } catch let error as NSError {
            print("Failed to set input or output format with error: \(error.localizedDescription)")
        }
        
        interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        
    }
    
    public func argmax(array: [Double]) -> Int {
        let output1 = array[0]
        let output2 = array[1]
        let output3 = array[2]
        
        if (output1 > output2 && output1 > output3){
            return 0
        } else if(output2 > output1 && output2 > output3){
            return 1
        } else{
            return 2
        }
    }
    
    public func estimateDistanceInfo(time: Double, sensorData: SensorData) -> UnitDistance{
        // feature extraction
        // ACC X, Y, Z, Norm Smoothing
        // Use y, z, norm variance (2sec)
        
        let accNorm = CF.l2Normalize(originalVector: sensorData.acc)
        
        updateAccYQue(buffer: accYQue, data: sensorData.acc[1])
        updateAccZQue(buffer: accZQue, data: sensorData.acc[2])
        updateAccNormQue(buffer: accNormQue, data: accNorm)
        
        let accYVar = Float(PDF.calVariance(buffer: accYQue))
        let accZVar = Float(PDF.calVariance(buffer: accZQue))
        let accNormVar = Float(PDF.calVariance(buffer: accNormQue))
        
        let input: [Float32] = [accYVar, accZVar, accNormVar]
        let inputs = ModelInputs()
        var inputData = Data()
        
        for i in 0..<input.count {
            var value = input[i]
            let elementSize = MemoryLayout.size(ofValue: value)
            var bytes = [UInt8](repeating: 0, count: elementSize)
            memcpy(&bytes, &value, elementSize)
            inputData.append(&bytes, count: elementSize)
        }
    
        // ---------- //
        do {
          try inputs.addInput(inputData)
        } catch let error {
          print("add input failure: \(error)")
        }
        
        interpreter.run(inputs: inputs, options: ioOptions) {
            outputs, error in
            guard error == nil, let outputs = outputs else {
                print("interpreter error")
                if (error != nil) {
                    print(error!)
                }
                return
            }

            do {
                let result = try outputs.output(index: 0) as! [[NSNumber]]
                print("Model Result :", result[0])
            } catch {
                //error
            }
        }
        // ------------- //
        
        finalUnitResult.isIndexChanged = false
        
        if (epoch == 0) {
            index+=1
//            var argMaxIndex: Int = argmax(array: output[0])
//            var velocity = 0
//
//            if (argMaxIndex ==  1) {
//                velocity = 4
//            } else if (argMaxIndex == 2) {
//                velocity = -2
//            }
        }
        
        epoch+=1
        
        if (epoch == OUTPUT_SAMPLE_TIME) {
            epoch = 0
        }
        
        return finalUnitResult
    }
    
    
    public func updateAccYQue(buffer: [Double], data: Double) {
        if (accYQue.count >= FEATURE_EXTRATION_SIZE) {
            accYQue.remove(at: 0)
        }
        accYQue.append(data)
    }
    
    public func updateAccZQue(buffer: [Double], data: Double) {
        if (accZQue.count >= FEATURE_EXTRATION_SIZE) {
            accZQue.remove(at: 0)
        }
        accZQue.append(data)
    }
    
    public func updateAccNormQue(buffer: [Double], data: Double) {
        if (accNormQue.count >= FEATURE_EXTRATION_SIZE) {
            accNormQue.remove(at: 0)
        }
        accNormQue.append(data)
    }
}
