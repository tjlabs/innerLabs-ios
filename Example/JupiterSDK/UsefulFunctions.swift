import Foundation

public func removeValuesWith_D(in dictionary: [String: [String]]) -> [String: [String]] {
    var updatedDictionary = dictionary
    
    for (key, values) in dictionary {
        let filteredValues = values.filter { !$0.contains("_D") }
        updatedDictionary[key] = filteredValues
    }
    
    return updatedDictionary
}
