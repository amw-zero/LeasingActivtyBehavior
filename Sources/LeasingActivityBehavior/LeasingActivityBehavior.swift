import Foundation

public class DealShell {
    let serverRepository: ServerRepository
    var deals: [Deal] = [] {
        didSet {
            subscription(deals)
        }
    }
    public var subscription: ([Deal]) -> Void = { _ in }
    
    var dealCount: Int {
        return deals.count
    }
    
    public init(serverRepository: ServerRepository) {
        self.serverRepository = serverRepository
    }
    
    public func createDeal(requirementSize: Int, tenantName: String) {
        let params: [String: Any] = [
            "requirementSize": requirementSize,
            "tenantName": tenantName
        ]
        guard let dealData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return
        }
        serverRepository.createDeal(data: dealData) { responseResult in
            switch responseResult {
            case let .success(data):
                let deal = try? JSONDecoder().decode(Deal.self, from: data)
                if let deal = deal { self.deals += [deal] }
            default:
                break
            }
        }
    }
    
    public func viewDeals() {
        serverRepository.viewDeals { responseResult in
            switch responseResult {
            case let .success(data):
                let deals = (try? JSONDecoder().decode([Deal].self, from: data)) ?? []
                self.deals = deals
            default:
                break
            }
        }
    }
}

public struct DealServer: ServerRepository {
    public var successfulResponse: Bool = true
    public typealias DealFunc = (Deal) -> Void
    public typealias DealsFunc = ([Deal]) -> Void
    public typealias DealCreateRepository = (Deal, @escaping DealFunc) -> Void
    public typealias DealIndexRepository = (@escaping DealsFunc) -> Void

    let createRepository: DealCreateRepository
    let indexRepository: DealIndexRepository
    
    public init(createRepository: @escaping DealCreateRepository, indexRepository: @escaping DealIndexRepository) {
        self.createRepository = createRepository
        self.indexRepository = indexRepository
    }
    
    public func createDeal(data: Data, onComplete: @escaping (NetworkResult<Data>) -> Void) {
        if !successfulResponse {
            onComplete(.error)
            return
        }
        guard let dealCreate = try? JSONDecoder().decode(Deal.self, from: data) else {
            onComplete(.error)
            return
        }
        createRepository(dealCreate) { deal in
            guard let dealData = try? JSONEncoder().encode(deal) else {
                onComplete(.error)
                return
            }

            onComplete(.success(dealData))
        }
    }
    
    public func viewDeals(onComplete: @escaping (NetworkResult<Data>) -> Void) {
        indexRepository { dealData in
            guard let dealData = try? JSONEncoder().encode(dealData) else {
                onComplete(.error)
                return
            }
            
            onComplete(.success(dealData))
        }
    }
}

public enum NetworkResult<T> {
    case error
    case success(T)
}

public struct Deal: Codable {
    public let id: Int?
    public let requirementSize: Int
    let tenantName: String
    
    public init(id: Int?, requirementSize: Int, tenantName: String) {
        self.id = id
        self.requirementSize = requirementSize
        self.tenantName = tenantName
    }
}

public protocol ServerRepository {
  var successfulResponse: Bool { get set }

  func createDeal(data: Data, onComplete: @escaping (NetworkResult<Data>) -> Void)
  func viewDeals(onComplete: @escaping (NetworkResult<Data>) -> Void)
}
