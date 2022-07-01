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
        case "mariner1":
            sectorDetectionService.startService(id: id)
        case "mariner2":
            buildingDetectionService.startService(id: id)
        case "mariner3":
            coarseLevelDetectionService.startService(id: id)
        case "venera":
            fineLevelDetectionService.startService(id: id)
        case "magellan":
            coarseLocationEstimationService.startService(id: id)
        case "jupiter":
            fineLocaationTrackingService.startService(id: id)
        default:
            sectorDetectionService.startService(id: id)
        }
    }
    
    public func stopService(service: String) {
        switch (service) {
        case "mariner1":
            sectorDetectionService.stopService()
        case "mariner2":
            buildingDetectionService.stopService()
        case "mariner3":
            coarseLevelDetectionService.stopService()
        case "venera":
            fineLevelDetectionService.stopService()
        case "magellan":
            coarseLocationEstimationService.stopService()
        case "jupiter":
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
