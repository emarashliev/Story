
import UIKit
import Combine

final class ListViewController: UIViewController {
    
    private enum Section { case items }
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item.ID>
    private typealias CellRegistration = UICollectionView.CellRegistration<ListCollectionCell, Item.ID>
    private typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<ListCollectionHeader>
    private typealias FooterRegistration = UICollectionView.SupplementaryRegistration<ListCollectionFooter>
    
    private var dataSource: DataSource! = nil
    private lazy var contentView = ListView()
    private let viewModel: ListViewModel
    
    init(viewModel: ListViewModel = ListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        configureCollectionView()
        configureNavigationBar()
        configureInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchFirstPage()
    }
}

// MARK: - configure CollectionView

extension ListViewController {
    private func configureCollectionView() {
        contentView.collectionView.delegate = self
        
        Task {
            for await query in viewModel.$lastQuery.values {
                await MainActor.run { [weak self]  in
                    if let collectionHeader = self?.getCollectionHeader(for: self?.contentView.collectionView) {
                        collectionHeader.text = "Query: \(query.capitalized)"
                    }
                }
            }
        }
        
        Task {
            for await _ in viewModel.$itemsStore.values {
                await MainActor.run { [weak self]  in
                    self?.updateSections()
                }
            }
        }
        
        Task {
            for await state in viewModel.$state.values {
                await MainActor.run { [weak self]  in
                    switch state {
                    case .initialLoading:
                        self?.contentView.startLoading()
                        if let collectionFooter = self?.getCollectionFooter(for: self?.contentView.collectionView) {
                            collectionFooter.startLoading()
                        }
                    case .loadedAllItems:
                        if let collectionFooter = self?.getCollectionFooter(for: self?.contentView.collectionView) {
                            collectionFooter.finishLoading()
                        }
                    case .finishedLoading:
                        self?.contentView.finishLoading()
                    case .error(let error):
                        self?.contentView.finishLoading()
                        self?.showError(error)
                    }
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { [unowned self] _ in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func configureInitialData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item.ID>()
        snapshot.appendSections([Section.items])
        snapshot.appendItems(viewModel.lastFetchedItemIDs, toSection: .items)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func updateSections() {
        var snapshot = dataSource.snapshot()
        snapshot.appendItems(viewModel.lastFetchedItemIDs, toSection: .items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate

extension ListViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if indexPath.row == viewModel.itemsStore.count - 1 {
            viewModel.fetchNextPage()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ListViewController {
    private func configureDataSource() {
        let cellRegistration = CellRegistration { [weak self] cell, _, itemID in
            guard let self = self else { return }
            guard let item = self.viewModel.itemsStore.fetchByID(itemID) else { return }
            
            cell.title.text = item.title
            cell.authors.text = "by \(item.authors.map { $0.name }.joined(separator: ","))"
            cell.narrators.text = "with \(item.narrators.map { $0.name }.joined(separator: ","))"
            
            let size = cell.cover.frame.size
            Task {
                if let image = await self.getCover(with: item, for: size) {
                    await MainActor.run {
                        cell.cover.image = image
                    }
                }
            }
        }
        
        
        dataSource = DataSource(collectionView: contentView.collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
        
        let headerRegistration = HeaderRegistration(elementKind: UICollectionView.elementKindSectionHeader) { _, _, _ in }
        let footerRegistration = FooterRegistration(elementKind: UICollectionView.elementKindSectionFooter) { _, _, _ in }
        dataSource.supplementaryViewProvider = { supplementaryView, supplementaryKind, indexPath in
            if supplementaryKind == UICollectionView.elementKindSectionHeader {
                return supplementaryView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            } else {
                return supplementaryView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
            }
        }
    }
}

// MARK: - Helpers

extension ListViewController {
    private func configureNavigationBar() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithTransparentBackground()
        standardAppearance.backgroundColor = .gray
        navigationItem.standardAppearance = standardAppearance
    }
    
    private func getCollectionHeader(for collectionView: UICollectionView?) -> ListCollectionHeader? {
        let supplementaryViews = collectionView?.visibleSupplementaryViews(
            ofKind: UICollectionView.elementKindSectionHeader
        )
        return supplementaryViews?.first as? ListCollectionHeader
    }
    
    private func getCollectionFooter(for collectionView: UICollectionView?) -> ListCollectionFooter? {
        let supplementaryViews = collectionView?.visibleSupplementaryViews(
            ofKind: UICollectionView.elementKindSectionFooter
        )
        return supplementaryViews?.first as? ListCollectionFooter
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
