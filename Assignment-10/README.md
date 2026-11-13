# Assignment 10 · Favorites Navigator

**Karas Yerassyl · Information Systems · KBTU**

**Theme — Movies.** Movie Navigator presents 20 films with original illustrations. Select a film to see its image, title, year and genre, personal rating and three-sentence description. Back and the edge swipe return to the list.

## Run

Open `FavoritesNavigator.xcodeproj` in Xcode, choose the **FavoritesNavigator** scheme and an iPhone Simulator, then press **Run**. The app uses UIKit and supports iOS 15 or later. Xcode 16 or later is needed for the iPhone 16 Pro Max simulator model.

## Implementation

- `Main.storyboard` defines the initial navigation controller, large list title, prototype cell, `showDetail` Show segue, detail screen and all Auto Layout constraints.
- `FavoriteLibrary` contains the 20 `FavoriteItem` values, including three-sentence descriptions.
- `FavoritesViewController` fills reusable cells and passes the selected item through `prepare(for:sender:)`. The selected row is deselected after returning to the list.
- `DetailViewController` fills its outlets in `viewDidLoad()`. Long text wraps inside a scroll view.
- Semantic colors provide a shared light and dark appearance. `LaunchScreen.storyboard` centers the film logo on the app background. `AppIcon` contains the opaque 1024 × 1024 image.

The ratings are sample personal selections. The geometric film illustrations were created for this project.

## Screenshots

<!-- screenshots:start -->

Simulator screenshots are pending. Run the capture command on a Mac to insert the list, detail, launch screen and Home Screen screenshots here.

<!-- screenshots:end -->

## Capture screenshots on a Mac

From this folder, run the following command in Terminal with Xcode and compatible iOS Simulator runtimes installed.

```bash
python3 scripts/capture_screenshots.py
```

The script builds the project and guides capture on iPhone SE (3rd generation) and iPhone 16 Pro Max. Follow the prompts to capture the list, select a movie for Detail, inspect the light and dark Launch Screen, and show the app icon on the Home Screen. For the launch image, confirm that the centered logo is actually visible. If the runtime cannot hold the launch screen, the script accepts a PNG screenshot of the corresponding LaunchScreen storyboard preview in Xcode.

After every required image is available, the script saves them to `Screenshots/` and embeds them above. Include that folder and the updated README in the GitHub commit.

Before submission, check Back and edge-swipe navigation, the complete description of a film with a long title, and the console for Auto Layout warnings. Open both storyboards in Interface Builder to check constraints on both devices. Source and resource checks were completed during preparation. The Xcode build and Simulator checks must be completed on a Mac.

Submit the unpacked project directory in the GitHub repository with this README, the screenshots and `.gitignore`.
