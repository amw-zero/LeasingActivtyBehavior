import Foundation

public enum DealFilter {
    case all
    case tenantName(String)
    
    init(fromQueryParams params: String?) {
        guard let params = params else {
            self = .all
            return
        }

        let queryComponents = URLComponents(string: "?\(params)")?.queryItems
        let tenantNameFilter = queryComponents?.filter { $0.name == "tenantName" }.first
        
        if let tenantName = tenantNameFilter?.value {
            self = .tenantName(tenantName)
        } else {
            self = .all
        }
    }
}

func filterQuery(from filter: DealFilter) -> String? {
    var queryParam: String? = nil
    if case let .tenantName(tenantName) = filter {
        queryParam = "tenantName=\(tenantName)"
    }
    
    return queryParam?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
}

public struct DealShellState {
    public var deals: [Deal]
    public var selectedDeal: Deal?
    public var errorMessage: String?
    
    public init(deals: [Deal] = [], selectedDeal: Deal? = nil, errorMessage: String? = nil) {
        self.deals = deals
        self.selectedDeal = selectedDeal
        self.errorMessage = errorMessage
    }
}

public class DealShell {
    let serverRepository: ServerRepository
    var state = DealShellState() {
        didSet {
            subscription(state)
        }
    }

    public var subscription: (DealShellState) -> Void = { _ in }
    
    var dealCount: Int {
        return state.deals.count
    }
    
    public init(serverRepository: ServerRepository) {
        self.serverRepository = serverRepository
    }

    public func addComment(_ comment: String, toDealWithId dealId: Int) {
        if let dealIndex = state.deals.firstIndex(where: { $0.id == dealId }) {
            let deal = state.deals[dealIndex]
            let comment = Comment(text: comment)
            let newDeal = Deal(
                id: deal.id,
                requirementSize: deal.requirementSize,
                tenantName: deal.tenantName,
                comments: deal.comments + [comment]
            )
            guard let commentData = try? JSONEncoder().encode(comment) else {
                return
            }
            
            serverRepository.addComment(toDealWithId: dealId, data: commentData) { result in
                
            }
            
            
            state.deals[dealIndex] = newDeal
            state.selectedDeal = newDeal
        } else {
            state.errorMessage = "Unable to add comment"
        }
    }
    
    public func createDeal(requirementSize: Int, tenantName: String) {
        let deal = Deal(requirementSize: requirementSize, tenantName: tenantName)
        guard let dealData = try? JSONEncoder().encode(deal) else {
            return
        }
        serverRepository.createDeal(data: dealData) { responseResult in
            switch responseResult {
            case let .success(data):
                let deal = try? JSONDecoder().decode(Deal.self, from: data)
                if let deal = deal { self.state.deals += [deal] }
            default:
                break
            }
        }
    }
    
    public func viewDeals(filter: DealFilter = .all) {
        serverRepository.viewDeals(queryParams: filterQuery(from: filter)) { responseResult in
            switch responseResult {
            case let .success(data):
                let deals = (try? JSONDecoder().decode([Deal].self, from: data)) ?? []
                self.state.deals = deals
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
    public typealias CommentFunc = (Comment) -> Void
    
    public typealias DealCreateRepository = (Deal, @escaping DealFunc) -> Void
    public typealias DealIndexRepository = (DealFilter, @escaping DealsFunc) -> Void
    public typealias CommentCreateRepository = (Comment, @escaping CommentFunc) -> Void

    let createRepository: DealCreateRepository
    let indexRepository: DealIndexRepository
    let commentCreateRepository: CommentCreateRepository
    
    public init(
        createRepository: @escaping DealCreateRepository,
        indexRepository: @escaping DealIndexRepository,
        commentCreateRepository: @escaping CommentCreateRepository
    ) {
        self.createRepository = createRepository
        self.indexRepository = indexRepository
        self.commentCreateRepository = commentCreateRepository
    }
    
    public func addComment(
        toDealWithId dealId: Int,
        data: Data,
        onComplete: @escaping (NetworkResult<Data>) -> Void
    ) {
        guard let comment = try? JSONDecoder().decode(Comment.self, from: data) else {
            onComplete(.error)
            return
        }
        
        commentCreateRepository(comment) { savedComment in
            guard let commentData = try? JSONEncoder().encode(savedComment) else {
                onComplete(.error)
                return
            }
            onComplete(.success(commentData))
        }
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
    
    public func viewDeals(queryParams: String?, onComplete: @escaping (NetworkResult<Data>) -> Void) {
        let filter = DealFilter(fromQueryParams: queryParams)
        indexRepository(filter) { deals in
            guard let dealData = try? JSONEncoder().encode(deals) else {
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

public struct Comment: Codable {
    public let id: Int?
    public let text: String
    
    public init(id: Int? = nil, text: String) {
        self.id = id
        self.text = text
    }
}

public struct Deal: Codable {
    public let id: Int?
    public let requirementSize: Int
    public let tenantName: String
    public var comments: [Comment]
    
    public init(id: Int? = nil, requirementSize: Int, tenantName: String, comments: [Comment] = []) {
        self.id = id
        self.requirementSize = requirementSize
        self.tenantName = tenantName
        self.comments = comments
    }
}

public protocol ServerRepository {
    func createDeal(data: Data, onComplete: @escaping (NetworkResult<Data>) -> Void)
    func viewDeals(queryParams: String?, onComplete: @escaping (NetworkResult<Data>) -> Void)
    func addComment(toDealWithId: Int, data: Data, onComplete: @escaping (NetworkResult<Data>) -> Void)
}

public func indexRepositoryContract(
    _ repository: @escaping ([Deal], DealFilter, @escaping DealServer.DealsFunc) -> Void,
    onComplete: @escaping (Bool) -> Void
) {
    func verifyAllFilter(onComplete: @escaping (Bool) -> Void) {
        let deals = [Deal.make()]
        repository(deals, .all) { indexDeals in
            onComplete(deals.map { $0.id } == indexDeals.map { $0.id })
        }
    }
    
    func verifyTenantNameFilter(onComplete: @escaping (Bool) -> Void) {
        let deals = [Deal.make(tenantName: "Tenant 1"), Deal.make(tenantName: "Tenant 2")]
        repository(deals, .tenantName("Tenant 2")) { indexDeals in
            onComplete(indexDeals.map { $0.tenantName } == ["Tenant 2"])
        }
    }
    
    verifyAllFilter { allFilterSucceeded in
        verifyTenantNameFilter { tenantNameFilterSucceeded in
            onComplete(allFilterSucceeded && tenantNameFilterSucceeded)
        }
    }
}

public func commentCreateRepositoryContract(
    _ repository: DealServer.CommentCreateRepository,
    onComplete: @escaping (Bool) -> Void
) {
    let newComment = Comment(text: "Test Comment")
    repository(newComment) { comment in
        onComplete(newComment.text == comment.text && comment.id != nil)
    }
}

extension Deal {
    static public func make(id: Int = 1, requirementSize: Int = 100, tenantName: String = "Company") -> Deal {
        return Deal(id: id, requirementSize: requirementSize, tenantName: tenantName)
    }
}
