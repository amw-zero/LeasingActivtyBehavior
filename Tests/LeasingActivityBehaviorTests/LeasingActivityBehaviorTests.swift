import XCTest
@testable import LeasingActivityBehavior

struct StubServerRepository: ServerRepository {
  var successfulResponse: Bool = true
  static var dealCount = 0
  
  func createDeal(requirementSize: Int, onComplete: @escaping (NetworkResult<Deal>) -> Void) {
    if successfulResponse {
      StubServerRepository.dealCount += 1
      onComplete(.success(Deal(id: StubServerRepository.dealCount, requirementSize: requirementSize)))
    } else {
      onComplete(.error)
      
    }
  }
}

extension DealShell {
  func hasDeal(id: Int) -> Bool {
    deals.contains { $0.id == id }
  }
}

func makeDealShell(isResponseSuccessful: Bool = true) -> DealShell {

  var repository = StubServerRepository()
  repository.successfulResponse = isResponseSuccessful
  
  return DealShell(repository: repository)
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
