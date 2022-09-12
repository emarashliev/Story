
import Foundation
import Combine

enum ServiceError: Error {
    case url(URLError)
    case urlRequest
    case decode
}

protocol ServiceProtocol {
    func get(page: Int?, query: String) -> AnyPublisher<ItemData, Error>
}

final class StoryService: ServiceProtocol {
    
    func get(page: Int?, query: String) -> AnyPublisher<ItemData, Error> {
        var dataTask: URLSessionDataTask?
        
        let onSubscription: (Subscription) -> Void = { _ in dataTask?.resume() }
        let onCancel: () -> Void = { dataTask?.cancel() }
        
        return Future<ItemData, Error> { [weak self] promise in
            guard let urlRequest = self?.getUrlRequest(page: page, query: query) else {
                promise(.failure(ServiceError.urlRequest))
                return
            }
            
            dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
                guard let data = data else {
                    if let error = error {
                        promise(.failure(error))
                    }
                    return
                }
                do {
                    let queryData = try JSONDecoder().decode(ItemData.self, from: data)
                    promise(.success(queryData))
                } catch {
                    promise(.failure(ServiceError.decode))
                }
            }
        }
        .handleEvents(receiveSubscription: onSubscription, receiveCancel: onCancel)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    private func getUrlRequest(page: Int?, query: String) -> URLRequest? {
        var components = URLComponents(string: "https://api.storytel.net/search/client")
        components?.queryItems = []
        
        if let page = page {
            components?.queryItems?.append(contentsOf: [
                URLQueryItem(name: "page", value: "\(page)")
            ])
        }
        
        components?.queryItems?.append(contentsOf: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "searchFor", value: "books"),
            URLQueryItem(name: "store", value: "STHP-SE"),
        ])
        guard let url = components?.url else { return nil }
        
        return URLRequest(url: url)
    }
}
