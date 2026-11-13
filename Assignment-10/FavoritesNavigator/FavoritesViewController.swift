import UIKit

final class FavoritesViewController: UIViewController, UITableViewDataSource {
    @IBOutlet private weak var tableView: UITableView!

    private let items = FavoriteLibrary.items
    private let reuseIdentifier = "FavoriteCell"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: animated)
        }
    }

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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail",
              let detailController = segue.destination as? DetailViewController,
              let selectedRow = tableView.indexPathForSelectedRow else {
            return
        }

        detailController.item = items[selectedRow.row]
    }
}
