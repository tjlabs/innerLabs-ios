import Foundation

public func removeValuesWith_D(in dictionary: [String: [String]]) -> [String: [String]] {
    var updatedDictionary = dictionary
    
    for (key, values) in dictionary {
        let filteredValues = values.filter { !$0.contains("_D") }
        updatedDictionary[key] = filteredValues
    }
    
    return updatedDictionary
}

public func getLocalTimeString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    dateFormatter.locale = Locale(identifier:"ko_KR")
    let nowDate = Date()
    let convertNowStr = dateFormatter.string(from: nowDate)
    
    return convertNowStr
}

