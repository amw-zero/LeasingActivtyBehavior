import Foundation

public class DealShell {
  let serverLinkage: ServerLinkage
  var deals: [Deal] = [] {
    didSet {
        subscription(deals)
    }
  }
  public var subscription: ([Deal]) -> Void = { _ in }
  
  public init(serverLinkage: @escaping ServerLinkage) {
    self.serverLinkage = serverLinkage
  }
  
  public func createDeal(requirementSize: Int) {
    do {
      let params = [
        "requirementSize": requirementSize
      ]
      let dealData = try JSONSerialization.data(withJSONObject: params, options: [])
      serverLinkage(dealData) { responseResult in
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

public class DealServer {
  public var successfulResponse: Bool = true
  public typealias DealFunc = (Deal) -> Void
  public typealias DealCreateRepository = (Deal, @escaping DealFunc) -> Void

  public init() {
  }

  public func createDeal(data: Data, repository: DealCreateRepository, onComplete: @escaping (NetworkResult<Data>) -> Void) {
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

public typealias RequestFunc = (NetworkResult<Data>) -> Void
public typealias ServerLinkage = (Data, @escaping RequestFunc) -> Void
