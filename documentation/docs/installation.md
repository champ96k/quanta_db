---
sidebar_position: 2
---

# Installation

## Adding the Dependency

To start using QuantaDB, add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  quanta_db: ^0.0.6 # Use the latest version
```

Then, run:

```bash
# For Dart projects
dart pub get

# For Flutter projects
flutter pub get
```

## Importing the Package

Import the package in your Dart code:

```dart
import 'package:quanta_db/quanta_db.dart';
```

## Platform Support

QuantaDB works on all platforms supported by Dart/Flutter:

- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ✅ Web (with IndexedDB adapter)

## Build Configuration

Add the following to your `build.yaml` file to configure code generation:

```yaml
targets:
  $default:
    builders:
      quanta_db:
        options:
          # Enable debug logging
          debug: false

          # Custom output directory (optional)
          output_dir: lib/generated
```

## Development Dependencies

For development, you might want to add these optional dependencies:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  quanta_db_generator: ^0.0.5
```

## Code Generation

After setting up your models, run the code generator:

```bash
# For Dart projects
dart run build_runner build

# For Flutter projects
flutter pub run build_runner build
```

For continuous generation during development:

```bash
# For Dart projects
dart run build_runner watch

# For Flutter projects
flutter pub run build_runner watch
```

## Verifying Installation

To verify your installation, try this simple test:

```dart
import 'package:quanta_db/quanta_db.dart';

void main() async {
  final db = await QuantaDB.open('test_db');
  print('Database opened successfully!');
  await db.close();
}
```

## Troubleshooting

If you encounter any issues:

1. **Version Conflicts**

   - Check for compatible versions of dependencies
   - Update to the latest version of QuantaDB
   - Clear pub cache: `dart pub cache clean`

2. **Code Generation Issues**

   - Delete the `build` directory
   - Run `dart pub get` again
   - Restart the code generator

3. **Platform-Specific Issues**
   - Check platform permissions
   - Verify storage access
   - Review platform-specific setup

## Next Steps

- Read the [Getting Started](getting-started) guide
- Check out the [Examples](https://github.com/champ96k/quanta_db/tree/master/example) directory
- Review the [API Reference](https://quantadb.netlify.app/)
