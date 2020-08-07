import XCTest
@testable import TransferPublisher
import Combine
#if os(iOS)  // TODO: Just need to include AppKit for the macOS test
import UIKit


final class TransferPublisherTests: XCTestCase {
  
  var cancellables = Set<AnyCancellable>()
  
  // Just a simple test to download and see progress in console
  func testSimpleDownload() {
    
    let waiter = XCTWaiter()
    let networkResponded = XCTestExpectation()
    
    let request = URLRequest(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/89/Wilkin_River_close_to_its_confluence_with_Makarora_River%2C_Otago%2C_New_Zealand.jpg")!)
    
    URLSession(configuration: .default).downloadTaskSimplePublisher(with: request)
      .sink(receiveCompletion: { (completion) in
        print(completion)
        networkResponded.fulfill()
      }) { (output) in
        print(output)
        if case .complete(let data) = output {
          print("Received file: \(data.count)")
          let image = UIImage(data: data)
          print(image.debugDescription)
          XCTAssert(data.isEmpty == false)
          XCTAssert(image != nil)
        }
    }.store(in: &cancellables)
    
    waiter.wait(for: [networkResponded], timeout: 30)
    
  }
  
  func testDownload() {
    
    let waiter = XCTWaiter()
    let networkResponded = XCTestExpectation()
    
    let request = URLRequest(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/89/Wilkin_River_close_to_its_confluence_with_Makarora_River%2C_Otago%2C_New_Zealand.jpg")!)
    
    URLSession(configuration: .default).downloadTaskPublisher(with: request)
      .sink(receiveCompletion: { (completion) in
        print(completion)
        networkResponded.fulfill()
      }) { (output) in
        print(output)
        if case .complete(let data) = output {
          print("Received file: \(data.count)")
          let image = UIImage(data: data)
          print(image.debugDescription)
          XCTAssert(data.isEmpty == false)
          XCTAssert(image != nil)
        }
    }.store(in: &cancellables)
    
    waiter.wait(for: [networkResponded], timeout: 30)
    
  }
  
}

#endif
