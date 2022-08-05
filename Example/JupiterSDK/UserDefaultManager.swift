import Foundation

struct UserDefaultManager {
    static var displayName: String {
        get {
            UserDefaults.standard.string(forKey: "DisplayName") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DisplayName")
        }
    }
}
