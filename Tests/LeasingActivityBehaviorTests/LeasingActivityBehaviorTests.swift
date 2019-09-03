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

extension Deal {
    static func make(id: Int = 1, requirementSize: Int = 100, tenantName: String = "Company") -> Deal {
        return Deal(id: id, requirementSize: requirementSize, tenantName: tenantName)
    }
}

let dealCreateRepo: (Deal, @escaping (Deal) -> Void) -> Void = { deal, onComplete in
    let dealWithId = Deal.make(id: 1, requirementSize: deal.requirementSize)
  onComplete(dealWithId)
}

let dealIndexRepository: (@escaping DealServer.DealsFunc) -> Void = { onComplete in
    onComplete([
        Deal.make(id: 1, requirementSize: 100),
        Deal.make(id: 2, requirementSize: 200),
    ])
}

func makeDealShell(
    isResponseSuccessful: Bool = true,
    createRepository: @escaping DealServer.DealCreateRepository = dealCreateRepo,
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
        let shell = makeDealShell(indexRepository: { onComplete in
            onComplete([Deal]())
        })

        shell.viewDeals()

        XCTAssertEqual(shell.dealCount, 0)
    }
    
    func testFilteringDealListByTenantName() {
        let deals = [
            Deal.make(tenantName: "Tenant 1"),
            Deal.make(tenantName: "Tenant 2"),
        ]
        let shell = makeDealShell(indexRepository: { onComplete in
            onComplete(deals)
        })
        
        shell.viewDeals(filter: .tenantName("Tenant 2"))
        
        XCTAssertEqual(shell.tenantName(at: 0), "Tenant 2")
    }
}
