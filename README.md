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

## 🛠 Usage

### 1. Add the dependency

In your `pubspec.yaml`:

```yaml
dev_dependencies:
  import_generator: ^0.0.3

Run the following command to generate the `all_exports.dart` file:

```shell
dart run import_generator
