//
//  Network.swift
//  Timer
//
//  Created by Maksym Bilokhatniuk on 23.06.2021.
//

import Foundation

typealias Callback<T> = (Result<T, Error>) -> Void

class Networking: NSObject {
  private var backgroundDownloadTask: URLSessionDownloadTask?
  private var backgroundCallback: Callback<Bool>?

    func get(taskId: String, callback: @escaping Callback<Bool>) {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/comments?postId=1")
    else {
      callback(.failure(URLError(.badURL)))
      return
    }
    // Notice the URLSessionConfiguration.background, usage of delegates, and downloadTask
    let session = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: taskId),
                             delegate: self,
                             delegateQueue: nil)
    let task = session.downloadTask(with: url)
    backgroundDownloadTask = task
    backgroundCallback = callback
    task.resume()
  }
}

extension Networking: URLSessionTaskDelegate {
  // Implement this method to handle download task errors.
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    if let error = error {
      backgroundCallback?(.failure(error))
      backgroundCallback = nil
    }
 }
}

extension Networking: URLSessionDownloadDelegate {
  // This is ridiculous but it's what we have to do - read JSON from the temp file
  // download task created for us.
  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    guard downloadTask.originalRequest?.url == backgroundDownloadTask?.originalRequest?.url
    else {
      return
    }
    print("Finished downloading background task: \(location)")
    do {
      let jsonData = try Data(contentsOf: location, options: [])
      backgroundCallback?(.success(true))
    } catch {
      backgroundCallback?(.failure(error))
    }
    backgroundDownloadTask = nil
    backgroundCallback = nil
  }
}
