import Foundation
import Combine

fileprivate class CancellableStore {
  static let shared = CancellableStore()
  var cancellables = Set<AnyCancellable>()
}

public enum DownloadOutput {
   case complete(Data)
   case downloading(transferred: Int64 = 0, expected: Int64 = 0) // cumulative bytes transferred, total bytes expected
 }
  
extension URLSession {
  
  public func downloadTaskPublisher(with request: URLRequest) -> AnyPublisher<DownloadOutput, Error> {
  
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
      .debounce(for: .seconds(0.3), scheduler: RunLoop.current) // adjust
     
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

// MARK: Error Types

public enum TransferError: Error {
  case httpError(HTTPURLResponse)
  case urlError(URLError)
}
