
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
    private var bindings = Set<AnyCancellable>()
    
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
        
        viewModel.$lastQuery
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] query in
                if let collectionHeader = self?.getCollectionHeader(for: self?.contentView.collectionView) {
                    collectionHeader.text = "Query: \(query.capitalized)"
                }
            })
            .store(in: &bindings)
        
        viewModel.$itemsStore
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.updateSections()
            })
            .store(in: &bindings)
        
        let stateValueHandler: (ListViewModelState) -> Void = { [weak self] state in
            switch state {
            case .initialLoading:
                self?.contentView.startLoading()
            case .loading:
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
        
        viewModel.$state
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink(receiveValue: stateValueHandler)
            .store(in: &bindings)
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
        let cellRegistration = CellRegistration { [weak self] cell, indexPath, itemID in
            guard let self = self else { return }
            guard let item = self.viewModel.itemsStore.fetchByID(itemID) else { return }
            
            cell.title.text = item.title
            cell.authors.text = "by \(item.authors.map { $0.name }.joined(separator: ","))"
            cell.narrators.text = "with \(item.narrators.map { $0.name }.joined(separator: ","))"
            
            let size = cell.cover.frame.size
            Task {
                if let sizedImage = try? await self.setCover(with: item, for: size) {
                    await MainActor.run {
                        cell.cover.image = sizedImage
                    }
                }
            }
        }
        
        
        dataSource = DataSource(collectionView: contentView.collectionView) { collectionView, indexPath, identifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
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
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = .gray
        
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundColor = .clear
        navigationItem.standardAppearance = standardAppearance
        navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
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
    
    @ImageCache private func setCover(with item: Item, for size: CGSize) async throws -> UIImage? {
        let scale =  size.height / CGFloat(item.formats.first?.cover.height ?? 1)
        let image = try await ImageCache.shared.load(url: item.formats.first?.cover.url, scale: scale)
        return await image?.byPreparingForDisplay()
    }
}
