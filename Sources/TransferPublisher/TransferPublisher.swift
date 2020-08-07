import Foundation
import Combine

// MARK: Download Publisher

public struct TaskOutput {
  let taskId: Int
  let taskDescription: String
  let taskState: URLSessionTask.State
  enum TransferState {
    case complete(Data)
    case transferring(Progress)
  }
  let transferState: TransferState
}

public enum DownloadOutput {
  case complete(Data)
  case downloading(transferred: Int64 = 0, expected: Int64 = 0) // cumulative bytes transferred, total bytes expec@available(OSX 10.13, *)
}

@available(OSX 10.15, *)
extension URLSession {
  
  public func downloadTaskPublisher(with request: URLRequest) -> AnyPublisher<TaskOutput, Error> {
  
    let subject = PassthroughSubject<TaskOutput, Error>()
   
    let task = downloadTask(with: request) { (tempURL, response, error) in
      
      guard error == nil else {
        subject.send(completion: .failure(error!))
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse else {
        let error = TransferError.urlError(URLError(.badServerResponse))
        subject.send(completion: .failure(error))
        return
      }
      
      // handle 304 in an outer layer
      guard httpResponse.statusCode == 200 else {
        let error = TransferError.httpError(httpResponse)
        subject.send(completion: .failure(error))
        return
      }
      
      guard let url = tempURL else {
        let error = TransferError.urlError(URLError(.fileDoesNotExist))
        // not the most appropriate error message, but at a low-level that's exactly the error
        subject.send(completion: .failure(error))
        return
      }
      
      do {
        let data = try Data(contentsOf: url, options: [.dataReadingMapped, .uncached])
        subject.send(task.com)
        subject.send(completion: .finished)
      } catch {
        subject.send(completion: .failure(error))
        return
      }

    }
    
    task.taskDescription = request.url?.absoluteString
    
    let fractionCompletePublisher = task.publisher(for: \.progress.fractionCompleted)
      .debounce(for: .seconds(progressInterval), scheduler: RunLoop.current) // adjust
    
    let statePublisher = task.publisher(for: \.state, options: [.initial, .new])

    Publishers.CombineLatest(fractionCompletePublisher, statePublisher)
      .sink {
        subject.send(transferringTaskOutput)
    }.store(in: &CancellableStore.shared.cancellables)
    
    task.resume()
    
    return subject.eraseToAnyPublisher()
    
  }
  
  public func downloadTaskSimplePublisher(with request: URLRequest) -> AnyPublisher<DownloadOutput, Error> {
  
    let subject = PassthroughSubject<DownloadOutput, Error>()
   
    let task = downloadTask(with: request) { (tempURL, response, error) in
      
      guard error == nil else {
        subject.send(completion: .failure(error!))
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse else {
        let error = TransferError.urlError(URLError(.badServerResponse))
        subject.send(completion: .failure(error))
        return
      }
      
      // handle 304 in an outer layer
      guard httpResponse.statusCode == 200 else {
        let error = TransferError.httpError(httpResponse)
        subject.send(completion: .failure(error))
        return
      }
      
      guard let url = tempURL else {
        let error = TransferError.urlError(URLError(.fileDoesNotExist))
        // not the most appropriate error message, but at a low-level that's exactly the error
        subject.send(completion: .failure(error))
        return
      }
      
      do {
        let data = try Data(contentsOf: url, options: [.dataReadingMapped, .uncached])
        subject.send(.complete(data))
        subject.send(completion: .finished)
      } catch {
        subject.send(completion: .failure(error))
        return
      }

    }
    
    task.taskDescription = request.url?.absoluteString
    
    let receivedPublisher = task.publisher(for: \.countOfBytesReceived)
      .debounce(for: .seconds(0.1), scheduler: RunLoop.current) // adjust
     
    let expectedPublisher = task.publisher(for: \.countOfBytesExpectedToReceive, options: [.initial, .new])
    
    Publishers.CombineLatest(receivedPublisher, expectedPublisher)
      .sink {
        let (received, expected) = $0
        let output = DownloadOutput.downloading(transferred: received, expected: expected)
        subject.send(output)
    }.store(in: &CancellableStore.shared.cancellables)
    
    task.resume()
    
    return subject.eraseToAnyPublisher()
    
  }
  
}

// MARK: Upload Publisher

public enum UploadOutput {
  case complete(Data?) // response body data, if any
  case uploading(transferred: Int64 = 0, expected: Int64 = 0) // cumulative bytes transferred, total bytes expected
}

@available(OSX 10.15, *)
extension URLSession {
  
  // MARK: Upload Task
  
  public func uploadTaskPublisher(with request: URLRequest, data: Data?) -> AnyPublisher<UploadOutput, Error> {
  
    let subject = PassthroughSubject<UploadOutput, Error>()
    
    let task = uploadTask(with: request, from: data) {
      (responseData, response, error) in
      
      guard error == nil else {
        subject.send(completion: .failure(error!))
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse else {
        let error = TransferError.urlError(URLError(.badServerResponse))
        subject.send(completion: .failure(error))
        return
      }
      
      // should be 201, but could vary
      guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 400 else {
        let error = TransferError.httpError(httpResponse)
        subject.send(completion: .failure(error))
        return
      }
      
      subject.send(.complete(data)) // maybe don't publish at all if nil
      subject.send(completion: .finished)

    }
    
    task.taskDescription = request.url?.absoluteString
    
    let receivedPublisher = task.publisher(for: \.countOfBytesSent)
      .debounce(for: .seconds(0.1), scheduler: RunLoop.current) // adjust
     
    let expectedPublisher = task.publisher(for: \.countOfBytesExpectedToSend, options: [.initial, .new])
    
    Publishers.CombineLatest(receivedPublisher, expectedPublisher)
      .sink {
        let (received, expected) = $0
        let output = UploadOutput.uploading(transferred: received, expected: expected)
        subject.send(output)
    }.store(in: &CancellableStore.shared.cancellables)
    
    task.resume()
    
    return subject.eraseToAnyPublisher()
    
  }
  
}

// MARK: Error Types

public enum TransferError: Error {
  case httpError(HTTPURLResponse)
  case urlError(URLError)
}

// MARK: Reference Storage

fileprivate class CancellableStore {
  static let shared = CancellableStore()
  var cancellables = Set<AnyCancellable>()
}

