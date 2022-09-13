

import UIKit

final class ListCollectionCell: UICollectionViewCell {
    static let identifier = "ListCollectionCell"
    
    lazy var cover = UIImageView(image: UIImage(systemName: "text.book.closed"))
    lazy var title = UILabel()
    lazy var authors = UILabel()
    lazy var narrators = UILabel()
    
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
        cover.image = UIImage(systemName: "text.book.closed")
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
        
        subviews.forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            cover.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            cover.widthAnchor.constraint(equalTo: cover.heightAnchor),

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
}
