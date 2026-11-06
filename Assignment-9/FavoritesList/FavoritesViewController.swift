import UIKit

final class FavoritesViewController: UIViewController, UITableViewDataSource {
    private let items = FavoriteLibrary.items
    private let reuseIdentifier = "FavoriteCell"

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        if let favoriteCell = cell as? FavoriteCell {
            favoriteCell.configure(with: items[indexPath.row])
        }
        return cell
    }
}
