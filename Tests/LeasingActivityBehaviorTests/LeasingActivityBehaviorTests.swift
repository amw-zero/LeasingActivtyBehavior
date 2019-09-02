import XCTest
@testable import LeasingActivityBehavior

extension DealShell {
  func hasDeal(id: Int) -> Bool {
    deals.contains { $0.id == id }
  }
}

func makeDealShell(isResponseSuccessful: Bool = true) -> DealShell {
  let dealCreateRepo: (Deal, @escaping (Deal) -> Void) -> Void = { deal, onComplete in
    let dealWithId = Deal(id: 1, requirementSize: deal.requirementSize)
    onComplete(dealWithId)
  }
    
    let server = DealServer(repository: dealCreateRepo)
    server.successfulResponse = isResponseSuccessful

  return DealShell(serverRepository: server)
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
