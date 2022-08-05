import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import UIKit

final class AppController {
    static let shared = AppController()
    private var window: UIWindow!
    private var vc: UIViewController?
    
    private var rootViewController: UIViewController? {
        didSet {
            window.rootViewController = rootViewController
//            window.inputViewController = rootViewController
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(checkSignIn),
                                               name: .AuthStateDidChange,
                                               object: nil)
    }
    
    func show(in window: UIWindow?) {
        guard let window = window else {
            fatalError("Cannot layout app with a nil window.")
        }
        self.window = window
        window.tintColor = .primary
        window.backgroundColor = .systemBackground
        checkSignIn()
        window.makeKeyAndVisible()
    }

    @objc private func checkSignIn() {
        if let user = Auth.auth().currentUser {
            setChannelScene(with: user)
        } else {
            print("Cannot enter the Chat")
        }
    }
    
    private func setChannelScene(with user: User) {
        let channelVC = ChannelVC(currentUser: user)
        
        rootViewController = BaseNavigationController(rootViewController: channelVC)
    }
}
