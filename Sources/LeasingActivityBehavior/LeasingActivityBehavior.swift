import Foundation

public class DealShell {
    let serverRepository: ServerRepository
    var deals: [Deal] = [] {
        didSet {
            subscription(deals)
        }
    }
    public var subscription: ([Deal]) -> Void = { _ in }
    
    public init(serverRepository: ServerRepository) {
        self.serverRepository = serverRepository
    }
    
    public func createDeal(requirementSize: Int) {
        do {
            let params = [
                "requirementSize": requirementSize
            ]
            let dealData = try JSONSerialization.data(withJSONObject: params, options: [])
            serverRepository.createDeal(data: dealData) { responseResult in
                switch responseResult {
                case let .success(data):
                    do {
                        let deal = try JSONDecoder().decode(Deal.self, from: data)
                        self.deals = self.deals + [deal]
                    } catch {
                        
                    }
                default:
                    break
                }
            }
        } catch {
            
        }
    }
}

public class DealServer: ServerRepository {
    public var successfulResponse: Bool = true
    public typealias DealFunc = (Deal) -> Void
    public typealias DealCreateRepository = (Deal, @escaping DealFunc) -> Void
    let repository: DealCreateRepository
    
    public init(repository: @escaping DealCreateRepository) {
        self.repository = repository
    }
    
    public func createDeal(data: Data, onComplete: @escaping (NetworkResult<Data>) -> Void) {
        if !successfulResponse {
            onComplete(.error)
            return
        }
        
        do {
            let dealCreate = try JSONDecoder().decode(Deal.self, from: data)
            repository(dealCreate) { deal in
                do {
                    let dealData = try JSONEncoder().encode(deal)
                    onComplete(.success(dealData))
                } catch {
                    
                }
            }
            
        } catch {
            onComplete(.error)
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
    
    public init(id: Int?, requirementSize: Int) {
        self.id = id
        self.requirementSize = requirementSize
    }
}

public protocol ServerRepository {
  var successfulResponse: Bool { get set }

  func createDeal(data: Data, onComplete: @escaping (NetworkResult<Data>) -> Void)
}
