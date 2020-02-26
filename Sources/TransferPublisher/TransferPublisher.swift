import Foundation
import Combine

public class TransferSession: URLSession {
    
  public override init() {
    let delegate = TransferSessionDelegate()
    let queue = DispatchQueue(label: "TransferSessionDelegate", qos: .default, attributes: .concurrent)
    super.init(configuration: .default, delegate: delegate, delegateQueue: queue)
    self.delegate = TransferSessionDelegate()
  }
  
  public protocol TransferOutput {
    var bytesTransferred: Int { get }
    var bytesExpected: Int { get }
  }
  
  public struct DownloadOutput: TransferOutput {
    let data: Data? = nil
    let bytesTransferred: Int = 0
    let bytesExpected: Int = 0
  }
  
  fileprivate var tasks: [Int: AnyPublisher] = [:]
  
  public func downloadTask(with request: URLRequest) -> AnyPublisher<DownloadOutput, Error> {
  
    let subject = PassthroughSubject<DownloadOutput, Error>()
    let task = downloadTask(with: request)
    task.taskDescription = request.url?.absoluteString
    self.tasks[task.taskIdentifier] = subject
    return subject
    
  }
  
  
  public func downloadTask2(with request: URLRequest) -> AnyPublisher<DownloadOutput, Error> {
  
    let subject = PassthroughSubject<DownloadOutput, Error>()
    let task = downloadTask(with: request)
    task.taskDescription = request.url?.absoluteString
    self.tasks[task.taskIdentifier] = subject
    return subject
    
  }
  
}

// MARK: Error Types

public enum TransferError: Error {
  case httpError(URLHttpResponse)
  case urlError(URLError)
}

// MARK: Delegate

private class TransferSessionDelegate: URLSessionDelegate, URLSessionDownloadDelegate, URLSessionDataTask {
  
  // progress
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    
    guard let session = session as? TransferSession else { return }
    
    guard let publisher = session.tasks[downloadTask.taskIdentifier] else {
      print("No reference to download task \(downloadTask.taskIdentifier)")
      return
    }
    
  }
  
  // success
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//    guard let url = tempURL else {
//             let error = TransferError.urlError(URLError(.fileDoesNotExist))
//             // not the most appropriate error message, but at a low-level that's exactly the error
//             subject.send(completion: .finished(error))
//             return
//           }
//
//           do {
//             let data = try Data(contentsOf: url, options: [.dataReadingMapped, .uncached])
//             subject.send()
//             subject.send(completion: .finished)
//           } catch {
//             subject.send(completion: .finished(error))
//             return
//           }
//
//
//         }
//
//       }
//
//    }
  }
  
  // error
   func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    //    Unlike URLSessionDataTask or URLSessionUploadTask, a download task reports server-side errors reported through HTTP status codes into corresponding NSError objects. << Apple Docs
    
  }
  
  // other

  func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
    
  }
  
  func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

    
  }

  
}

