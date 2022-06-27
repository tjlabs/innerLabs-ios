//
//  ServiceManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/06/24.
//

import Foundation

public class ServiceManager: NSObject {
    
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
    
    public func startService(service: String) {
        switch (service) {
        case "mariner1":
            sectorDetectionService.startService()
        case "mariner2":
            buildingDetectionService.startService()
        case "mariner3":
            coarseLevelDetectionService.startService()
        case "venera":
            fineLevelDetectionService.startService()
        case "magellan":
            coarseLocationEstimationService.startService()
        case "jupiter":
            fineLocaationTrackingService.startService()
        default:
            sectorDetectionService.startService()
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
}
