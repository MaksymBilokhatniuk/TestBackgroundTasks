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
//e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"bgTaskKey"]
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       // bgTaskKey
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidEnterBackground),
                                               name: Notification.Name("sceneDidEnterBackground"), object: nil)
        
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isAllow, error in
            
        }
       
        if #available(iOS 13, *) {
//            BGTaskScheduler.shared.register(forTaskWithIdentifier: "bgTaskKey", using: nil) { task in
//
//                CordovaIOSPlugin.shared.getUndeliveredNotification { result in
//                    task.setTaskCompleted(success: true)
//                    print("task dome")
//                    self.scheduleAppRefresh()
//                }
//            }
            
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "qweqwe", using: nil) { task in
                  
                CordovaIOSPlugin.shared.getUndeliveredNotification { result in
                    task.setTaskCompleted(success: true)
                    print("task2 dome")
                    self.scheduleBackgroundProcessing()
                }
              }
        }
        
        return true
    }
    
    @objc func sceneDidEnterBackground() {
        
//        self.scheduleAppRefresh()
        scheduleBackgroundProcessing()
    }
    
    @available(iOS 13.0, *)
      func scheduleBackgroundProcessing() {
          let request = BGProcessingTaskRequest(identifier: "qweqwe")
          request.requiresNetworkConnectivity = true // Need to true if your task need to network process. Defaults to false.
          request.requiresExternalPower = false // Need to true if your task requires a device connected to power source. Defaults to false.

          request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // Process after 5 minutes.

          do {
              try BGTaskScheduler.shared.submit(request)
            print("123")
          } catch {
              print("Could not schedule image fetch: (error)")
          }
      }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
        
        let request = BGAppRefreshTaskRequest(identifier: "bgTaskKey")
       
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // Refresh after 5 minutes.
        
        do {
        
            try BGTaskScheduler.shared.submit(request)
            print("success request")
            
        } catch {
            print("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }

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
class CordovaIOSPlugin: NSObject, UNUserNotificationCenterDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    
    static let shared = CordovaIOSPlugin()
    private override init() { }
    
    @objc private func notificationPermissionRequest() {
        
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            
            if settings.authorizationStatus == .authorized {
                
                self.createLocalNotification()
            }
        })

    }
    
    @objc private func createLocalNotification() {
      
        let content = UNMutableNotificationContent()

        content.title = "DHL push delivery"
        content.subtitle = "Test local push"
        content.body = "Hello body"
        content.categoryIdentifier = "actionCategory"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        self.completionHandler(.newData)
    }
    
    var completionHandler: (UIBackgroundFetchResult) -> Void = { _ in }
    
    func getUndeliveredNotification(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/comments?postId=1") else { return }
        self.completionHandler = completionHandler
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.my.app")
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = true
        configuration.allowsCellularAccess = true
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.waitsForConnectivity = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    
        let task = session.downloadTask(with: request)

        if #available(iOS 11, *) {
            task.countOfBytesClientExpectsToSend = 200
            task.countOfBytesClientExpectsToReceive = 1700
        }
        task.resume()
        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            self.notificationPermissionRequest(completionHandler: completionHandler)
//        }.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.notificationPermissionRequest()
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(error?.localizedDescription)
    }
   
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


