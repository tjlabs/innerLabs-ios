import UIKit
import GoogleMaps
import FirebaseCore
import Flutter
import FlutterPluginRegistrant

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    
//    var window: UIWindow?
    
    private let flutterGroup: FlutterEngineGroup = .init(name: "map_ui_module", project: nil)
    private(set) var mapEngine: FlutterEngine?
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Google Maps
        GMSServices.provideAPIKey("AIzaSyAGA86GDZ3me4mkBHHdKcv_KSgGqzXveLU")
        FirebaseApp.configure()
        
        mapEngine = flutterGroup.makeEngine(withEntrypoint: nil, libraryURI: nil, initialRoute: "/map")
        guard let mapEngine else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        GeneratedPluginRegistrant.register(with: mapEngine)
        
        RemoteConfigManager.sharedManager.launching(completionHandler: { (config) in }, forceUpdate: {
            (forceUpdate) in
            if !forceUpdate {
//                let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateInitialViewController()
//                self.window?.rootViewController = vc
//                self.window?.makeKeyAndVisible()
            }
        })
        return true
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

