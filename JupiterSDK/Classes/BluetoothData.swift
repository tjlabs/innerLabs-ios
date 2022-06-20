import Foundation

// BLE Data

//struct BLEDeviceItem: Codable {
//    var bleName: String
//    var RSSI: Int
//    var URLString: String
//}
//
//struct BLEDevices: Codable {
//    var devices: [FingerPrint]
//}
//
//class BLEList {
//    let encoder = JSONEncoder()
//    let decoder = JSONDecoder()
//    
//    var bleList = BLEDevices(devices:[])
//    
//    init() {
//        
//    }
//    
//    func encodeToJson() -> String {
//        var r:String = ""
//        let jsonData = try? encoder.encode(bleList)
//        
//        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8){
//            r = jsonString
//        }
//        
//        return r
//    }
//    
//    func insertDevice(_ device: FingerPrint) {
//        var found:Bool = false
//        var foundIdx:Int = 0
//        for i in bleList.devices {
//            if i.ward_id == device.ward_id {
//                found = true
//                break
//            }
//            foundIdx += 1
//        }
//        if found == false {
//            bleList.devices.append(device)
//            
//        }
//        else {
//            if device.rssi > bleList.devices[foundIdx].rssi {
//                bleList.devices[foundIdx].rssi = device.rssi
//            }
//            
//        }
//    }
//    
//    func resetList() {
//        bleList.devices.removeAll()
//    }
//}
//
//class BeaconInfo {
//    let encoder = JSONEncoder()
//    let decoder = JSONDecoder()
//    
//    var bleList = BLEDevices(devices:[])
//    
//    init() {
//        
//    }
//    
//    func encodeToJson() -> String {
//        var r:String = ""
//        let jsonData = try? encoder.encode(bleList)
//        
//        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8){
//            r = jsonString
//        }
//        
//        return r
//    }
//    
//    func insertDevice(_ device: FingerPrint) {
//        var found:Bool = false
//        
//        // 같은 ID 찾기
//        var foundIdx:Int = 0
//        for i in bleList.devices {
//            if i.ward_id == device.ward_id {
//                found = true
//                break
//            }
//            foundIdx += 1
//        }
//        
//        // 같은 ID가 없으면 추가
//        if found == false {
//            bleList.devices.append(device)
//            
//        }
//        
//        // 같은 ID가 있으면 더 센 신호로 갱신
//        else {
//            if device.rssi > bleList.devices[foundIdx].rssi {
//                bleList.devices[foundIdx].rssi = device.rssi
//            }
//            
//        }
//    }
//    
//    func resetList() {
//        bleList.devices.removeAll()
//    }
//}
