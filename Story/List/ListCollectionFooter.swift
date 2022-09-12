
import UIKit
import Combine

final class ListCollectionFooter: UICollectionReusableView {
    
    static let reuseIdentifier = "ListCollectionFooter"
    
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }
}

extension ListCollectionFooter {
    func startLoading() {
        activityIndicatorView.startAnimating()
    }
    
    func finishLoading() {
        activityIndicatorView.stopAnimating()
    }
    
    private func configure() {
        addSubview(activityIndicatorView)
        backgroundColor = .clear
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .black
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            activityIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}
