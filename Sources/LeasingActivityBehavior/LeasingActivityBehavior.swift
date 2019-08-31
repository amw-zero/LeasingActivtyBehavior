class DealShell {
  let repository: ServerRepository
  var deals: [Deal] = [] {
      didSet {
          subscription(deals)
      }
  }
  var subscription: ([Deal]) -> Void = { _ in }
  
  init(repository: ServerRepository) {
      self.repository = repository
  }
  
  func createDeal(requirementSize: Int) {
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

enum NetworkResult<T> {
    case error
    case success(T)
}

struct Deal: Codable {
    let id: Int?
    let requirementSize: Int
}

protocol ServerRepository {
    var successfulResponse: Bool { get set }
    
    func createDeal(requirementSize: Int, onComplete: @escaping (NetworkResult<Deal>) -> Void)
}
