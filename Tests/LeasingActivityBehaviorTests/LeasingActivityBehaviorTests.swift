import XCTest
@testable import LeasingActivityBehavior

extension DealShell {
    func hasDeal(id: Int) -> Bool {
        deals.contains { $0.id == id }
    }
    
    func requirementSize(at index: Int) -> Int {
        deals[index].requirementSize
    }
}

let dealCreateRepo: (Deal, @escaping (Deal) -> Void) -> Void = { deal, onComplete in
  let dealWithId = Deal(id: 1, requirementSize: deal.requirementSize)
  onComplete(dealWithId)
}

let dealIndexRepository: (@escaping DealServer.DealsFunc) -> Void = { onComplete in
    onComplete([
        Deal(id: 1, requirementSize: 100),
        Deal(id: 2, requirementSize: 200),
    ])
}

func makeDealShell(
    isResponseSuccessful: Bool = true,
    createRepository: @escaping DealServer.DealCreateRepository = dealCreateRepo,
    indexRepository: @escaping DealServer.DealIndexRepository = dealIndexRepository
) -> DealShell {
    let server = DealServer(createRepository: createRepository, indexRepository: indexRepository)
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
    
    func testViewingDealList() {
        let shell = makeDealShell()
        
        shell.viewDeals()
        
        XCTAssertEqual(shell.requirementSize(at: 0), 100)
        XCTAssertEqual(shell.requirementSize(at: 1), 200)
    }
    
//    func testViewingDealListWithNoDeals() {
//        let shell = makeDealShell()
//
//        shell.viewDeals()
//
//        XCTAssertEqual(shell.dealCount, 0)
//    }
}
