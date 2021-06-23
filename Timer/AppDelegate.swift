//
//  AppDelegate.swift
//  Timer
//
//  Created by Maksym Bilokhatniuk on 20.06.2021.
//

import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let networking = Networking()
//e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"BGAppRefreshTaskRequest"]
    //e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"BGAppRefreshTaskRequest || BGProcessingTaskRequest"]
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       // bgTaskKey
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidEnterBackground),
                                               name: Notification.Name("sceneDidEnterBackground"), object: nil)
        
//        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isAllow, error in
            
        }
       
        if #available(iOS 13, *) {
            
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "BGAppRefreshTaskRequest",
                                            using: nil) { task in
                
                task.expirationHandler = {
                    print("Task expired")
                    task.setTaskCompleted(success: false)
                  }
                
                
                self.networking.get(taskId: "BGAppRefreshTaskRequest") { result in
                    
                    switch result {
                    
                    case .success(let success):
                        CordovaIOSPlugin.shared.createLocalNotification { _ in
                            task.setTaskCompleted(success: success)
                        }
                        task.setTaskCompleted(success: success)
                    case .failure(let error):
                        print(error.localizedDescription)
                        task.setTaskCompleted(success: false)
                    }
                }
            }
            
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "BGProcessingTaskRequest",
                                            using: nil) { task in
                
                task.expirationHandler = {
                    print("Task expired")
                    task.setTaskCompleted(success: false)
                  }
                
                self.networking.get(taskId: "BGProcessingTaskRequest") { result in
                    
                    switch result {
                    
                    case .success(let success):
                        CordovaIOSPlugin.shared.createLocalNotification { _ in
                            task.setTaskCompleted(success: success)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                        task.setTaskCompleted(success: false)
                    }
                }
              
            }
        }
        
        return true
    }
    
    @objc func sceneDidEnterBackground() {
        
        scheduleAppRefresh()
        scheduleBackgroundProcessing()
        print("")
    }
    
    @available(iOS 13.0, *)
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "BGAppRefreshTaskRequest")

        request.earliestBeginDate = Date().addingTimeInterval(TimeInterval(60))  // Refresh after 1 minutes.

        do {
            try BGTaskScheduler.shared.submit(request)
            print("BGAppRefreshTaskRequest success request")
        } catch {
            print("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }
    
    func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: "BGProcessingTaskRequest")
        request.requiresNetworkConnectivity = true // Need to true if your task need to network process. Defaults to false.
        request.requiresExternalPower = false // Need to true if your task requires a device connected to power source. Defaults to false.
        
        request.earliestBeginDate = Date().addingTimeInterval(TimeInterval(60))  // Process after 1 minutes.
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("BGProcessingTaskRequest succes request")
        } catch {
            print("Could not schedule image fetch: (error)")
        }
    }
    
    @available(iOS 13.0, *)

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
      
        if #available(iOS 13, *) {
            
            self.scheduleAppRefresh()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("1")
    }
    
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        print("downloaded")
        completionHandler()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response.notification.request.content.userInfo)
        completionHandler()
    }
}
