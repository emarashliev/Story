
import UIKit

final class ListCollectionCellViewModel {
    @Published var title: String?
    @Published var authors: String?
    @Published var narrators: String?
    @Published var image: UIImage?
        
    private let item: Item
    private let coverSize: CGSize
    private var imageTask: Task<(), Never>?
    
    init(item: Item, coverSize: CGSize) {
        self.item = item
        self.coverSize = coverSize
        
        configure()
    }
    
    func resetCell() {
        imageTask?.cancel()
        title = ""
        authors = ""
        narrators = ""
        image = nil
    }
    
    private func configure() {
        title = item.title
        authors = "by \(item.authors.map { $0.name }.joined(separator: ","))"
        narrators = "with \(item.narrators.map { $0.name }.joined(separator: ","))"
        
        imageTask = Task.detached { [weak self] in
            guard let self = self else { return }

            if let image = await self.getCover(with: self.item, for: self.coverSize) {
                await MainActor.run {
                    self.image = image
                }
            }
        }
    }
    
    @ImageCache private func getCover(with item: Item, for size: CGSize) async -> UIImage? {
        let scale =  size.height / CGFloat(item.formats.first?.cover.height ?? 1)
        var image: UIImage? = nil
        do {
            image = try await ImageCache.shared.load(url: item.formats.first?.cover.url, scale: scale)
        } catch {
            print("ImageCache ERROR: \(error.localizedDescription)")
        }
        return await image?.byPreparingForDisplay()
    }
}
