
import Foundation

struct Item: Identifiable {
    
    let id = UUID()
    let title: String
    let authors: [Person]
    let narrators: [Person]
    let formats: [Format]
}

extension Item: Decodable {
    enum CodingKeys: String, CodingKey {
        case title
        case authors
        case narrators
        case formats
    }
}

extension Item {
    struct Person: Decodable {
        let id: String
        let name: String
    }
    
    struct Format: Decodable {
        let cover: Cover
        
        struct Cover: Decodable {
            let url: String
            let width: Int
            let height: Int
        }
    }
}
