import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Main.storyboard is selected in Info.plist.
        // UIKit creates the window and the initial ViewController from that file.
        guard scene is UIWindowScene else { return }
    }
}
