import UIKit

final class FavoriteCell: UITableViewCell {
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var filmTitleLabel: UILabel!

    func configure(with item: FavoriteItem) {
        posterImageView.image = UIImage(named: item.imageName)
        filmTitleLabel.text = item.title
        accessibilityLabel = item.title
    }
}
