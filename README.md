# Review - Plex Dashboard

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg?logo=swift)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/github/license/Loriage/Review?color=%239944ee)](./LICENSE)
[![Made with SwiftUI](https://img.shields.io/badge/Made%20with-SwiftUI-blue.svg?logo=swift)](https://developer.apple.com/xcode/swiftui/)

**Review** is a native iOS application that provides a comprehensive dashboard for your Plex Media Server. It connects directly to your server's official API, meaning **no third-party tools are required**.

The app allows you to monitor current activity, explore your libraries, get detailed statistics about your media consumption, and manage your server and library settings.

> [!IMPORTANT]  
> A working Plex Media Server instance accessible from the internet is required to use **Review**.
> Plex Pass is **not** necessary for most features.

## Overview

**Review** offers a range of features to enhance your Plex experience, from real-time activity monitoring to in-depth media analysis. The intuitive interface is designed to provide quick access to all the information you need about your server and viewing habits.

## Key Features

-   **Real-time activity monitoring**: Keep an eye on who is watching what on your server in real-time, with details about the stream, player, and location.
-   **In-depth statistics**: Sync your entire watch history to unlock detailed statistics. Discover your top movies, shows, and most active users. Get fun facts about your viewing habits, such as your most active day of the week and peak viewing times.
-   **Media management**: Take full control of your media. Refresh metadata, analyze media files, change posters, and correct media matches directly from the app.
-   **Server & Libraries settings**: Fine-tune your Plex server with access to advanced preferences. Manage library settings, scan for new files, and empty the trash to keep everything tidy.
-   **Library exploration**: Browse through your movie and TV show libraries, view details, and explore your media collection with an intuitive interface.
-   **Powerful search**: Quickly find any media in your libraries with a powerful and fast search functionality.
-   **Secure connection**: Your credentials are encrypted and securely stored in the iOS Keychain.

## Roadmap

-   [ ] **Widgets**: Get at-a-glance information about your server's activity directly from your home screen.
-   [ ] **Push Notifications**: Receive alerts for important server events or when new content is added.
-   [ ] **Localization**: Support for additional languages to make the app accessible to a wider audience. (Contributions are welcome!)

## Technologies Used

-   **SwiftUI**: For creating a declarative and reactive user interface that is consistent across all Apple platforms.
-   **Swift Charts**: To build beautiful and interactive charts for visualizing your media statistics.
-   **Swift Concurrency (`async/await`)**: For performing network requests and other asynchronous tasks in a modern and efficient way.
-   **Combine**: For managing the state of shared objects and ensuring a responsive user experience.

## Screenshots

<p align="center">
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/activity.jpg" alt="Activity Feed Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/libraries.jpg" alt="Libraries View Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/library-detail.jpg" alt="Library Details Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/all-stats.jpg" alt="All Stats Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/user-stats.jpg" alt="User Stats Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/media-detail.jpg" alt="Media Details Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/show-seasons.jpg" alt="Show Seasons Screenshot" width="100"/>
  <img src="https://github.com/Loriage/Review/blob/main/screenshots/library-settings.jpg" alt="Library Settings Screenshot" width="100"/>
</p>


## Installation

You can install Review on your iOS device through the App Store or by sideloading the `.ipa` file from the [releases](https://github.com/Loriage/Review-Swift-App/releases/latest) page.

## Support

If you find this application useful and would like to support its development, you can do so through the following platforms:

-   [Buy Me a Coffee](https://buymeacoffee.com/loriage)
-   [GitHub Sponsors](https://github.com/sponsors/Loriage)

Your support is greatly appreciated and helps in maintaining and improving the app.

## License

This project is distributed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
