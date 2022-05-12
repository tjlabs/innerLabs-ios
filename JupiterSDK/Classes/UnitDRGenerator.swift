//
//  UnitDRGenerator.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/05/12.
//

import Foundation
import FirebaseCore
import FirebaseMLCommon

public class UnitDRGenerator: NSObject {
    
    public override init() {
        
    }
    
    var model: LocalModel!
    //    var interpreter: ModelIn
    
//    public func loadModel() {
//        let conditions = ModelDownloadConditions(allowsCellularAccess: false, allowsBackgroundDownloading: true)
//        ModelDownloader.modelDownloader()
//            .getModel(name: "your_model",
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
//                        let interpreter = try Interpreter(modelPath: customModel.path)
//                    } catch {
//                        // Error. Bad model file?
//                    }
//                case .failure(let error):
//                    // Download was unsuccessful. Don't enable ML features.
//                    print(error)
//                }
//            }
//
//    }
}
