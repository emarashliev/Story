
import XCTest
import Combine
@testable import Story

class StoryTests: XCTestCase {
    
    @MainActor func testViewModelState_initialLoading() throws {
        let mockService = MockService()
        let viewModel = ListViewModel(storyService: mockService)
        viewModel.fetchFirstPage()
        XCTAssertEqual(viewModel.state, .initialLoading)
    }
    
    @MainActor func testViewModelState_loading() throws {
        let mockService = MockService()
        let viewModel = ListViewModel(storyService: mockService)
        viewModel.fetchNextPage()
        XCTAssertEqual(viewModel.state, .loading)
    }
    
    @MainActor func testViewModelState_finishedLoading() throws {
        let mockService = MockService()
        let viewModel = ListViewModel(storyService: mockService)
        viewModel.fetchFirstPage()
        mockService.subject.send(completion: .finished)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.state, .finishedLoading)
        }
    }
    
    @MainActor func testViewModelState_loadedAllItems() throws {
        let mockService = MockService()
        let viewModel = ListViewModel(storyService: mockService)
        viewModel.fetchFirstPage()
        mockService.subject.send(ItemData(query: "harry", nextPageToken: nil, items: []))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.state, .loadedAllItems)
        }
    }
}

fileprivate class MockService: Service {
    let subject = PassthroughSubject<ItemData, Error>()
    
    func get(page: Int?, query: String) -> AnyPublisher<ItemData, Error> {
        let subject = PassthroughSubject<ItemData, Error>()
        return subject.eraseToAnyPublisher()
    }
}
