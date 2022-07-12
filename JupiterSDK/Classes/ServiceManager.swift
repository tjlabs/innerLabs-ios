//
//  ServiceManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/06/24.
//

import Foundation

public class ServiceManager: NSObject {
    
    var user_id: String = ""
    var sector_id: Int = 0
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
    
    public func startService(id: String, sector_id: Int, service: String) {
        switch (service) {
        case "SD":
            sectorDetectionService.startService(id: id, sector_id: sector_id)
        case "BD":
            buildingDetectionService.startService(id: id, sector_id: sector_id)
        case "CLD":
            coarseLevelDetectionService.startService(id: id, sector_id: sector_id)
        case "FLD":
            fineLevelDetectionService.startService(id: id, sector_id: sector_id)
        case "CLE":
            coarseLocationEstimationService.startService(id: id, sector_id: sector_id)
        case "FLT":
            fineLocaationTrackingService.startService(id: id, sector_id: sector_id)
        default:
            sectorDetectionService.startService(id: id, sector_id: sector_id)
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
    
    public func getResult(sector_id: Int, service: String) -> Any {
        var result: Any?
        
        switch (service) {
        case "SD":
            result = sectorDetectionService.getResult()
        case "BD":
            result = buildingDetectionService.getResult()
        case "CLD":
            result = sectorDetectionService.getResult()
        case "FLD":
            result = fineLevelDetectionService.getResult()
        case "CLE":
            result = coarseLocationEstimationService.getResult()
        case "FLT":
            print("FLT Result")
//            fineLocaationTrackingService.stopService()
        default:
            print("Service Unavailable")
        }
        
        return result
    }
    
    public func initUser(id: String) {
        let deviceModel = deviceModel
        let osVersion = osVersion
        var initUser = InitUser(user_id: id, device_model: deviceModel, os_version: osVersion)
    }
}
