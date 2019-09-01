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
    repository.createDeal(requirementSize: requirementSize) { result in
        switch result {
        case let .success(deal):
            self.deals = self.deals + [deal]
        default:
            break
        }
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
  
  func createDeal(requirementSize: Int, onComplete: @escaping (NetworkResult<Deal>) -> Void)
}
