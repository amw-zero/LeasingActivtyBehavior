import Foundation

public class DealShell {
  let repository: ServerRepository
  var deals: [Deal] = [] {
    didSet {
        subscription(deals)
    }
  }
  public var subscription: ([Deal]) -> Void = { _ in }
  
  public init(repository: ServerRepository) {
    self.repository = repository
  }
  
  public func createDeal(requirementSize: Int) {
    do {
      let params = [
        "requirementSize": requirementSize
      ]
      let dealData = try JSONSerialization.data(withJSONObject: params, options: [])
      repository.createDeal(data: dealData) { result in
        switch result {
        case let .success(deal):
            self.deals = self.deals + [deal]
        default:
            break
        }
      }
    } catch {
      return 
    }
    
  }
}

public class DealServer: ServerRepository {
  public var successfulResponse: Bool = true

  public init() {
  }

  public func createDeal(data: Data, onComplete: @escaping (NetworkResult<Deal>) -> Void) {
    if !successfulResponse {
      onComplete(.error)
      return
    }

    do {
      let deal = try JSONDecoder().decode(Deal.self, from: data)
      let dealWithId = Deal(id: 1, requirementSize: deal.requirementSize)
      onComplete(.success(dealWithId))
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
  
  func createDeal(data: Data, onComplete: @escaping (NetworkResult<Deal>) -> Void)
}
