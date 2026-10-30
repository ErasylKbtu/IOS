import UIKit

final class ProfileViewController: UIViewController {
    @IBOutlet private weak var initialsLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var postsLabel: UILabel!
    @IBOutlet private weak var followersLabel: UILabel!
    @IBOutlet private weak var followingLabel: UILabel!
    @IBOutlet private weak var aboutLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Only text data is changed here. Every view, style and constraint
        // belongs to Main.storyboard and can be inspected in Interface Builder.
        let arguments = ProcessInfo.processInfo.arguments
        let testLongName = arguments.contains("--long-name")
        initialsLabel.text = testLongName ? "MH" : "AB"
        nameLabel.text = testLongName
            ? "Maximilian Alexander von Habsburg"
            : "Aigerim Bekova"
        subtitleLabel.text = "iOS Developer · Almaty"
        postsLabel.text = "128"
        followersLabel.text = "4.2K"
        followingLabel.text = "312"

        let about = "Building banking apps in Swift. I like clean architecture, coffee and long walks in the mountains around Almaty."
        aboutLabel.text = arguments.contains("--long-about")
            ? Array(repeating: about, count: 6).joined(separator: " ")
            : about
    }
}
