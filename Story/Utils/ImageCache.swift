
import UIKit

@globalActor actor ImageCache {
    static let shared  = ImageCache()
    
    private var cachedImages: NSCache<NSString, UIImage>

    init() {
        cachedImages = NSCache<NSString, UIImage>()
        cachedImages.totalCostLimit = 50_000_000
    }
    
    nonisolated func load(url: String?, scale: CGFloat) async throws -> UIImage? {
        guard let url = url, let url = URL(string: url) else { return  nil}
        
        if let cachedImage = await getImage(with: url) {
            return cachedImage
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data, scale: scale) else { return nil }
        await add(image: image, with: url)
        return image
    }
    
    private func add(image: UIImage, with url: URL) {
        let key = url.absoluteString as NSString
        cachedImages.setObject(image, forKey: key, cost: image.jpegData(compressionQuality: 1)?.count ?? 0)
    }
    
    private func getImage(with url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        return cachedImages.object(forKey: key)
    }
}
