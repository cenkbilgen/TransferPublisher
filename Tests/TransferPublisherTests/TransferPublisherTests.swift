import XCTest
@testable import TransferPublisher
import Combine
import CryptoKit


final class TransferPublisherTests: XCTestCase {
  
  var cancellables = Set<AnyCancellable>()
  
  let remoteFile: (url: URL, bytes: Int, sha256: String) = (URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/89/Wilkin_River_close_to_its_confluence_with_Makarora_River%2C_Otago%2C_New_Zealand.jpg")!,
                                                            20880207,
                                                            "d26366ce096a061fadcf7c95dbf82fc76aa19f52cfcbf51c3b67c5eac5518f9a")
  
  // Just a simple test to download and see progress in console
  func testDownload() {
    
    let waiter = XCTWaiter()
    let networkResponded = XCTestExpectation()
    
    let request = URLRequest(url: remoteFile.url)
    
    URLSession(configuration: .default).downloadTaskPublisher(with: request)
      .sink(receiveCompletion: { (completion) in
        print(completion)
        networkResponded.fulfill()
      }) { (output) in
        print(output)
        if case .complete(let data) = output {
          print("Received file: \(data.count)")
          XCTAssert(data.isEmpty == false, "no download data")
          XCTAssert(data.count == self.remoteFile.bytes, "byte count mismatch")
          var hash = CryptoKit.SHA256()
          hash.update(data: data)
          let digestString = hash.finalize().map({String(format: "%02hhx", $0)}).joined()
          print("hash: \(digestString)")
          XCTAssert(digestString == self.remoteFile.sha256, "download data hash mismatch")
        }
    }.store(in: &cancellables)
    
    waiter.wait(for: [networkResponded], timeout: 30)
    
  }
  
}

