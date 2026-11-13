import UIKit

final class DetailViewController: UIViewController {
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var filmTitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var firstStarImageView: UIImageView!
    @IBOutlet private weak var secondStarImageView: UIImageView!
    @IBOutlet private weak var thirdStarImageView: UIImageView!
    @IBOutlet private weak var fourthStarImageView: UIImageView!
    @IBOutlet private weak var fifthStarImageView: UIImageView!

    var item: FavoriteItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let item = item else { return }

        navigationItem.title = item.title
        posterImageView.image = UIImage(named: item.imageName)
        posterImageView.accessibilityLabel = "Illustration for \(item.title)"
        filmTitleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        descriptionLabel.text = item.description

        let stars: [UIImageView] = [
            firstStarImageView, secondStarImageView, thirdStarImageView,
            fourthStarImageView, fifthStarImageView
        ]
        for (index, star) in stars.enumerated() {
            star.image = UIImage(systemName: index < item.rating ? "star.fill" : "star")
        }
    }
}
