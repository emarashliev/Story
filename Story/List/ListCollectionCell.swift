

import UIKit
import Combine

final class ListCollectionCell: UICollectionViewCell {
    static let identifier = "ListCollectionCell"
    
    var viewModel: ListCollectionCellViewModel? {
        didSet { configureViewModel() }
    }
    
    lazy var cover = UIImageView()
    private lazy var title = UILabel()
    private lazy var authors = UILabel()
    private lazy var narrators = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)

    
    private var bindings = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        addSubiews()
        configureConstraints()
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        viewModel?.resetCell()
        bindings.removeAll()
        super.prepareForReuse()
    }
}

extension ListCollectionCell {
    private func addSubiews() {
        let subviews = [cover, title, authors, narrators]
        
        cover.tintColor = .black
        cover.contentMode = .scaleAspectFit
        cover.backgroundColor = UIColor(red: 0.9176, green: 0.9176, blue: 0.9176, alpha: 1.0)
        title.textColor = .black
        title.font = UIFont.boldSystemFont(ofSize: 17.0)
        authors.textColor = .gray
        narrators.textColor = .gray
        activityIndicatorView.hidesWhenStopped = true
        
        for view in subviews {
            contentView.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        cover.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            cover.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            cover.widthAnchor.constraint(equalTo: cover.heightAnchor),
            
            activityIndicatorView.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: cover.centerYAnchor),

            title.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 4),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            title.bottomAnchor.constraint(equalTo: authors.topAnchor, constant: -8),
            
            authors.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            authors.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 4),
            authors.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            narrators.topAnchor.constraint(equalTo: authors.bottomAnchor, constant: 2),
            narrators.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 4),
            narrators.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
        ])
    }
    
    private func configureViewModel() {
        viewModel?.$title
            .assign(to: \.text, on: title)
            .store(in: &bindings)
        
        viewModel?.$authors
            .assign(to: \.text, on: authors)
            .store(in: &bindings)
        
        viewModel?.$narrators
            .assign(to: \.text, on: narrators)
            .store(in: &bindings)
        
        viewModel?.$image
            .assign(to: \.image, on: cover)
            .store(in: &bindings)
        
        viewModel?.$activityIndicatorViewAnimating
            .sink { [weak self] animating in
                if animating {
                    self?.activityIndicatorView.startAnimating()
                } else {
                    self?.activityIndicatorView.stopAnimating()
                }
            }
            .store(in: &bindings)
    }
}
