# import_generator

A Dart CLI tool that automatically generates a single `all_exports.dart` file for your project, simplifying the task of organizing and categorizing imports across your `lib/` folder.

---

## 🚀 Features

- Automatically generates a clean and categorized `all_exports.dart` file.
- Supports:
  - Dart core libraries
  - Flutter core
  - External packages
  - Project-specific files
- Optional config file to exclude specific paths.

---



## Getting Started

1. **Add dependency:**
In your `pubspec.yaml`:
```yaml
dev_dependencies:
  import_generator: ^0.0.3
```

2. `Install Package` In your project:
```
flutter pub get
```

3. `Run The Following Command` In your Root Terminal:
```
dart run import_generator
```

