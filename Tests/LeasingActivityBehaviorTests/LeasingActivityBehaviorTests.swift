import XCTest
@testable import LeasingActivityBehavior

extension DealShell {
  func hasDeal(id: Int) -> Bool {
    deals.contains { $0.id == id }
  }
}

func makeDealShell(isResponseSuccessful: Bool = true) -> DealShell {
  let server = DealServer()
  server.successfulResponse = isResponseSuccessful
  let dealCreateRepo: (Deal, @escaping (Deal) -> Void) -> Void = { deal, onComplete in
    let dealWithId = Deal(id: 1, requirementSize: deal.requirementSize)
    onComplete(dealWithId)
  }

  return DealShell { dealData, onComplete in
    server.createDeal(data: dealData, repository: dealCreateRepo, onComplete: onComplete)
  }
}

final class LeasingActivityBehaviorTests: XCTestCase {
  func testCreatingADealSuccessfully() {
    let shell = makeDealShell()
    
    shell.createDeal(requirementSize: 1000)
    
    XCTAssertTrue(shell.hasDeal(id: 1))
  }
  
  func testCreatingADealError() {
    let shell = makeDealShell(isResponseSuccessful: false)
    
    shell.createDeal(requirementSize: 1000)
    
    XCTAssertFalse(shell.hasDeal(id: 1))
  }
}
