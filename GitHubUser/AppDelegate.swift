//
//  AppDelegate.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import UIKit
import CoreData
import Network

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    var isAppActive = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        LocalDBManager.firstSetup()
        ImageDownloader.firstSetup()
        NavigationCenter.startNavigation()
        whereIsMySQLite()
        setupNetworkMonitor()
        NetworkUtil.checkConnect { _ in
        }
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        isAppActive = true
    }
  
    func applicationDidEnterBackground(_ application: UIApplication) {
        LocalDBManager.saveContext()
        ImageDownloader.saveContext()
    }
    
    func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("We're connected!")
            } else {
                print("No connection.")
            }
            print("path.isExpensive: \(path.isExpensive)")
            // Delay 1 second to allow physical network device successfully connects
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
                NetworkUtil.checkConnect { connected in
                    if self.isAppActive {
                        NotificationCenter.post(NetworkUtil.KeyNetworkStatus, object: nil)
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
}

func whereIsMySQLite() {
    let path = FileManager
        .default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .last?
        .absoluteString
        .replacingOccurrences(of: "file://", with: "")
        .removingPercentEncoding

    print(path ?? "Not found")
}
