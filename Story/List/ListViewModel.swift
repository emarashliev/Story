
import Foundation
import Combine

enum ListViewModelError: Error, Equatable {
    case itemsFetch
}

enum ListViewModelState: Equatable {
    case initialLoading
    case finishedLoading
    case loadedAllItems
    case error(ListViewModelError)
}

final class ListViewModel {
        
    @MainActor @Published private(set) var itemsStore = AnyModelStore<Item>([])
    @MainActor @Published private(set) var state: ListViewModelState = .initialLoading
    @MainActor @Published private(set) var lastQuery: String = ""
    private(set) var lastFetchedItemIDs: [Item.ID] = []
    
    private var nextPageToken: Int? = 0
    private let storyService: Service
    private var bindings = Set<AnyCancellable>()

    init(storyService: Service = StoryService()) {
        self.storyService = storyService
    }
}

extension ListViewModel {
    @MainActor func fetchFirstPage() {
        state = .initialLoading
        fetchItems(page: 0)
    }
    
    @MainActor func fetchNextPage() {
        if let nextPageToken = nextPageToken {
            fetchItems(page: nextPageToken)
        }
    }
    
    @MainActor private func fetchItems(page: Int) {
        let completionHandler: (Subscribers.Completion<Error>) -> Void = { [weak self] completion in
            switch completion {
            case .failure(let error):
                print(error.localizedDescription)
                self?.state = .error(.itemsFetch)
            case .finished:
                if self?.nextPageToken == nil {
                    self?.state = .loadedAllItems
                } else {
                    self?.state = .finishedLoading
                }
            }
        }
        
        let valueHandler: (ItemData) -> Void = { [weak self] itemData in
            guard let self = self else { return }

            self.lastFetchedItemIDs = itemData.items.map { $0.id }
            self.itemsStore.append(models: itemData.items)
            
            if self.lastQuery != itemData.query {
                self.lastQuery = itemData.query
            }
            
            if let nextPageToken = itemData.nextPageToken {
                self.nextPageToken = Int(nextPageToken)
            } else {
                self.nextPageToken = nil
            }
        }
        
        storyService
            .get(page: page, query: "harry")
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink(receiveCompletion: completionHandler, receiveValue: valueHandler)
            .store(in: &bindings)
    }
}

