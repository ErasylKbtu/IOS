import UIKit

class ViewController: UIViewController {
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var randomButton: UIButton!

    private let favorites = FavoritesData.items
    private var currentIndex: Int?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()

        // The views and their frames are defined in Main.storyboard.
        posterImageView.layer.cornerRadius = 16
        posterImageView.clipsToBounds = true
        randomButton.layer.cornerRadius = 16

        // A complete card is shown immediately, before the first tap.
        if let firstIndex = favorites.indices.first {
            showFavorite(at: firstIndex)
        }
    }

    @IBAction private func pickFavorite(_ sender: UIButton) {
        var availableIndices: [Int] = []

        for index in favorites.indices {
            if let previousIndex = currentIndex {
                if index == previousIndex {
                    continue
                }
            }
            availableIndices.append(index)
        }

        // The current card is excluded, so consecutive repetitions are impossible.
        guard let nextIndex = availableIndices.randomElement() else { return }
        showFavorite(at: nextIndex)
    }

    private func showFavorite(at index: Int) {
        guard favorites.indices.contains(index) else { return }
        let favorite = favorites[index]

        posterImageView.image = UIImage(named: favorite.imageName)
        posterImageView.isAccessibilityElement = true
        posterImageView.accessibilityLabel = favorite.title
        titleLabel.text = favorite.title
        descriptionLabel.text = favorite.description
        currentIndex = index
    }
}
