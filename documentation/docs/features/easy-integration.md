---
sidebar_position: 5
---

# Easy Integration

Integrating QuantaDB into your Dart or Flutter applications is designed to be a straightforward process, allowing you to quickly incorporate a powerful local database into your project.

The ease of integration stems from several factors:

- **Pure Dart Package:** QuantaDB is distributed as a pure Dart package through pub.dev, the official package repository for Dart and Flutter. This means you can easily add it as a dependency to your `pubspec.yaml` file and fetch it using standard Dart/Flutter package management commands (`dart pub get` or `flutter pub get`).
- **Simple API:** The core API for interacting with QuantaDB is designed to be intuitive and easy to understand, covering essential database operations like opening/closing the database, putting, getting, and deleting data.
- **Automatic Platform Handling:** QuantaDB automatically manages platform-specific secure directories for storing database files, abstracting away the complexities of file system interactions on different operating systems.
- **Compatibility:** Built entirely in Dart, QuantaDB is compatible with all platforms supported by Dart and Flutter, ensuring a consistent development experience across mobile, desktop, and web (depending on specific features and platform support).

The combination of being a standard Dart package, a simple API, and automatic platform handling makes integrating QuantaDB into your development workflow a seamless process. 