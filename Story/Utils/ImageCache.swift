
import UIKit

final class ImageCache {
    
    static let shared = ImageCache()
    private let cachedImages = NSCache<NSURL, UIImage>()
    
    func load(url: String?) async throws -> UIImage? {
        guard let url = url, let nsurl = NSURL(string: url) else { return  nil}
        if let cachedImage = cachedImages.object(forKey: nsurl) {
            return cachedImage
        }
        
        let (data, _) = try await URLSession.shared.data(from: nsurl as URL)
        guard let image = UIImage(data: data) else { return nil }
        self.cachedImages.setObject(image, forKey: nsurl, cost: data.count)
        return image
    }
}
