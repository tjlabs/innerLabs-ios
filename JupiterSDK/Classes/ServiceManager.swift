//
//  ServiceManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/06/24.
//

import Foundation

public class ServiceManager: NSObject {
    
//    public var observers: [Observer]
    
    lazy var sectorDetectionService = SectorDetectionService()
    lazy var buildingDetectionService = BuildingDetectionService()
    lazy var coarseLevelDetectionService = CoarseLevelDetectionService()
    lazy var fineLevelDetectionService = FineLevelDetectionService()
    lazy var coarseLocationEstimationService = CoarseLocationEstimationService()
    lazy var fineLocationTrackingService = FineLocationTrackingService()
    
    // Check Subscriber
//    public func subscribe(observer: Observer, id: String, sector_id: Int, service: String, mode: String) {
//        self.observers.append(observer)
//
//        if (service == "FLD") {
//            fineLevelDetectionService.startService(id: id, sector_id: sector_id, service: service)
//        }
//    }
//
//    public func unsubscribe(observer: Observer, service: String) {
//        if let index = self.observers.firstIndex(where: { $0.service == observer.service }) {
//            self.observers.remove(at: index)
//        }
//    }
//
//    public func notify(message: String) {
//        for observer in observers {
//            observer.update(message: message)
//        }
//    }
    
    var user_id: String = ""
    var sector_id: Int = 0
    var mode: String = ""
    var service: String = ""
    
    var deviceModel: String = ""
    var os: String = ""
    var osVersion: Int = 0
    
    public override init() {
        deviceModel = UIDevice.modelName
        os = UIDevice.current.systemVersion
        let arr = os.components(separatedBy: ".")
        print("Device Model : \(deviceModel)")
        osVersion = Int(arr[0]) ?? 0
        print("OS : \(osVersion)")
    }
    
//    public init(observers: [Observer]) {
//        self.observers = observers
//
//        deviceModel = UIDevice.modelName
//        os = UIDevice.current.systemVersion
//        let arr = os.components(separatedBy: ".")
//        print("Device Model : \(deviceModel)")
//        osVersion = Int(arr[0]) ?? 0
//        print("OS : \(osVersion)")
//    }
    
    public func startService(id: String, sector_id: Int, service: String, mode: String) {
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
            fineLocationTrackingService.startService(id: id, sector_id: sector_id, mode: mode)
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
            fineLocationTrackingService.stopService()
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
            result = fineLocationTrackingService.getResult()
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
