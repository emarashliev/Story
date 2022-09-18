
import UIKit

@globalActor actor ImageCache {
    static let shared  = ImageCache()
    
    private let cachedImages: NSCache<NSURL, UIImage>
 
    init() {
        cachedImages = NSCache<NSURL, UIImage>()
        cachedImages.totalCostLimit = 50_000_000
    }
    
    func load(url: String?, scale: CGFloat) async throws -> UIImage? {
        guard let url = url, let nsurl = NSURL(string: url) else { return  nil}
        
        if let cachedImage = cachedImages.object(forKey: nsurl) {
            return cachedImage
        }
        
        let (data, _) = try await URLSession.shared.data(from: nsurl as URL)
        guard let image = UIImage(data: data, scale: scale) else { return nil }
        self.cachedImages.setObject(image, forKey: nsurl, cost: image.jpegData(compressionQuality: 1)?.count ?? 0)
        return image
    }
}
