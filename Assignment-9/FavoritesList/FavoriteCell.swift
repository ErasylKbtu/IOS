import UIKit

final class FavoriteCell: UITableViewCell {
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var filmTitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var firstStarImageView: UIImageView!
    @IBOutlet private weak var secondStarImageView: UIImageView!
    @IBOutlet private weak var thirdStarImageView: UIImageView!
    @IBOutlet private weak var fourthStarImageView: UIImageView!
    @IBOutlet private weak var fifthStarImageView: UIImageView!

    func configure(with item: FavoriteItem) {
        posterImageView.image = UIImage(named: item.imageName)
        filmTitleLabel.text = item.title
        subtitleLabel.text = item.subtitle

        let starImageViews: [UIImageView] = [
            firstStarImageView, secondStarImageView, thirdStarImageView,
            fourthStarImageView, fifthStarImageView
        ]
        for (index, starImageView) in starImageViews.enumerated() {
            let symbolName = index < item.rating ? "star.fill" : "star"
            starImageView.image = UIImage(systemName: symbolName)
        }

        isAccessibilityElement = true
        accessibilityLabel = "\(item.title), \(item.subtitle)"
        accessibilityValue = "\(item.rating) out of 5 stars"
    }
}
