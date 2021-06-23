//
//  Plugin.swift
//  Timer
//
//  Created by Maksym Bilokhatniuk on 23.06.2021.
//

import Foundation
import UserNotifications
import BackgroundTasks

class CordovaIOSPlugin: NSObject, UNUserNotificationCenterDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    
    static let shared = CordovaIOSPlugin()
    private override init() { }
    
    @objc private func notificationPermissionRequest() {
        
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            
            if settings.authorizationStatus == .authorized {
                
//                self.createLocalNotification()
            }
        })

    }
    
    func createLocalNotification(completion: @escaping (Bool) -> Void) {
      
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            
            if settings.authorizationStatus == .authorized {
                
               let content = UNMutableNotificationContent()
                
                content.title = "DHL push delivery"
                content.subtitle = "Test local push"
                content.body = "Hello body"
                content.categoryIdentifier = "actionCategory"
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        })
//        self.completionHandler(.newData)
    }
    
    func getUndeliveredNotification(completion: @escaping (Bool) -> Void) {
    
//        self.completionHandler = completionHandler
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/comments?postId=1") else { return }

        let configuration = URLSessionConfiguration.background(withIdentifier: "com.Timerqwe")
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
        print("task gone")
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
