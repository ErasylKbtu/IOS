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

<img width="589" height="1280" alt="image" src="https://github.com/user-attachments/assets/ee575c9c-aa79-4b32-82d5-aa11c06b53a0" />
<img width="589" height="1280" alt="image" src="https://github.com/user-attachments/assets/02f2238c-7a11-4c25-9167-4c7bc0d72c02" />
