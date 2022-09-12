
import Foundation

struct ItemData: Decodable {
    
    let query: String
    let nextPageToken: String?
    let items: [Item]
}
