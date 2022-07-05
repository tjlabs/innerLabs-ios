//
//  ServiceManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/06/24.
//

import Foundation

public class ServiceManager: NSObject {
    
    var user_id: String = ""
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    
    let sectorDetectionService = SectorDetectionService()
    let buildingDetectionService = BuildingDetectionService()
    let coarseLevelDetectionService = CoarseLevelDetectionService()
    let fineLevelDetectionService = FineLevelDetectionService()
    let coarseLocationEstimationService = CoarseLocationEstimationService()
    let fineLocaationTrackingService = FineLocationTrackingService()
    
    public override init() {
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        print("Device Model : \(deviceModel)")
        osVersion = Int(arr[0]) ?? 0
        print("OS : \(osVersion)")
    }
    
    public func startService(id: String, service: String) {
        switch (service) {
        case "SD":
            sectorDetectionService.startService(id: id)
        case "BD":
            buildingDetectionService.startService(id: id)
        case "CLD":
            coarseLevelDetectionService.startService(id: id)
        case "FLD":
            fineLevelDetectionService.startService(id: id)
        case "CLE":
            coarseLocationEstimationService.startService(id: id)
        case "FLT":
            fineLocaationTrackingService.startService(id: id)
        default:
            sectorDetectionService.startService(id: id)
        }
    }
    
    public func stopService(service: String) {
        switch (service) {
        case "SD":
            sectorDetectionService.stopService()
        case "BD":
            buildingDetectionService.stopService()
        case "CLD":
            coarseLevelDetectionService.stopService()
        case "FLD":
            fineLevelDetectionService.stopService()
        case "CLE":
            coarseLocationEstimationService.stopService()
        case "FLT":
            fineLocaationTrackingService.stopService()
        default:
            sectorDetectionService.stopService()
        }
    }
    
    public func getResult(service: String) {
    }
    
    public func initUser(id: String) {
        let deviceModel = deviceModel
        let osVersion = osVersion
        var initUser = InitUser(user_id: id, device_model: deviceModel, os_version: osVersion)
    }
}
