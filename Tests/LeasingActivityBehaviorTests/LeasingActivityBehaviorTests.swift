import XCTest
@testable import LeasingActivityBehavior

extension DealShell {
    func hasDeal(id: Int) -> Bool {
        deals.contains { $0.id == id }
    }
    
    func requirementSize(at index: Int) -> Int {
        deals[index].requirementSize
    }
    
    func tenantName(at index: Int) -> String {
        deals[index].tenantName
    }
}

let dealCreateRepository: (Deal, @escaping (Deal) -> Void) -> Void = { deal, onComplete in
    let dealWithId = Deal.make(id: 1, requirementSize: deal.requirementSize)
    onComplete(dealWithId)
}

func makeDealIndexRepository(deals: [Deal]) -> (DealFilter, @escaping DealServer.DealsFunc) -> Void {
    return { filter, onComplete in
        switch filter {
        case .all:
            onComplete(deals)
        case let .tenantName(name):
            onComplete(deals.filter { $0.tenantName == name })
        }
    }
}

let dealIndexRepository = makeDealIndexRepository(deals: [
    Deal.make(id: 1, requirementSize: 100),
    Deal.make(id: 2, requirementSize: 200),
])

func makeDealShell(
    isResponseSuccessful: Bool = true,
    createRepository: @escaping DealServer.DealCreateRepository = dealCreateRepository,
    indexRepository: @escaping DealServer.DealIndexRepository = dealIndexRepository
) -> DealShell {
    var server = DealServer(createRepository: createRepository, indexRepository: indexRepository)
    server.successfulResponse = isResponseSuccessful

    return DealShell(serverRepository: server)
}

final class LeasingActivityBehaviorTests: XCTestCase {
    func testCreatingADealSuccessfully() {
        let shell = makeDealShell()
        
        shell.createDeal(requirementSize: 1000, tenantName: "Test Tenant")
        
        XCTAssertTrue(shell.hasDeal(id: 1))
    }
    
    func testCreatingADealError() {
        let shell = makeDealShell(isResponseSuccessful: false)
        
        shell.createDeal(requirementSize: 1000, tenantName: "Test Tenant")
        
        XCTAssertFalse(shell.hasDeal(id: 1))
    }
    
    func testViewingDealList() {
        let shell = makeDealShell()
        
        shell.viewDeals()
        
        XCTAssertEqual(shell.requirementSize(at: 0), 100)
        XCTAssertEqual(shell.tenantName(at: 0), "Company")
        
        XCTAssertEqual(shell.requirementSize(at: 1), 200)
        XCTAssertEqual(shell.tenantName(at: 1), "Company")
    }
    
    func testViewingDealListWithNoDeals() {
        let shell = makeDealShell(indexRepository: { _, onComplete in
            onComplete([Deal]())
        })

        shell.viewDeals()

        XCTAssertEqual(shell.dealCount, 0)
    }
    
    func testFilteringDealListByTenantNameWhenResultsAreFound() {
        let shell = makeDealShell(indexRepository: makeDealIndexRepository(deals: [
            Deal.make(tenantName: "Tenant 1"),
            Deal.make(tenantName: "Tenant 2"),
        ]))
        
        shell.viewDeals(filter: .tenantName("Tenant 2"))
        
        XCTAssertEqual(shell.tenantName(at: 0), "Tenant 2")
    }
    
    func testFilteringDealListByTenantNameWhenResultsAreNotFound() {
        let shell = makeDealShell(indexRepository: makeDealIndexRepository(deals: [
            Deal.make(tenantName: "Tenant 1"),
            Deal.make(tenantName: "Tenant 2"),
        ]))
        
        shell.viewDeals(filter: .tenantName("Tenant 3"))
        
        XCTAssertEqual(shell.dealCount, 0)
    }
    
    func testFakeIndexRepositoryContract() {
        let expectation = self.expectation(description: "Index Repository Contract")
        indexRepositoryContract(makeDealIndexRepository) { success in
            expectation.fulfill()
            XCTAssert(success)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
