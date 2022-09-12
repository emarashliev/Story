
import Foundation

struct Item: Identifiable {
    
    let id: Int
    let title: String
    let authors: [Person]
    let narrators: [Person]
    let formats: [Format]
}

extension Item: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "bookId"
        case title
        case authors
        case narrators
        case formats
    }
}

extension Item: Hashable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        }
    }
}
