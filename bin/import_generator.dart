import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

void main() {
  // 1. Project setup
  final projectDir = Directory.current;
  final libDir = Directory(path.join(projectDir.path, 'lib'));

  if (!libDir.existsSync()) {
    print('❌ Error: lib directory not found');
    return;
  }

  // 2. Read project config
  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found');
    return;
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspecYaml = loadYaml(pubspecContent);
  final projectName = pubspecYaml['name'];

  // 3. Exclusion lists
  final excludedDirs = [
    'build',
    '.dart_tool',
    '.git',
    'android',
    'ios',
    'web',
    'test',
    'generated',
    'docs',
    'coverage',
    'example',
    'samples'
  ];

  final excludedFiles = ['.g.dart', '.freezed.dart', '.gr.dart', '.pb.dart'];

  // 4. Create exports file
  final generatedFile =
      File(path.join(libDir.path, 'core', 'all_exports.dart'));
  generatedFile.parent.createSync(recursive: true);

  // 5. Export structure with Flutter UI categories
  final exports = {
    'dart_core': [
      "// ┌───────────────────────────┐",
      "// │       Dart Core          │",
      "// └───────────────────────────┘",
      "export 'dart:async';",
      "export 'dart:convert';",
      "export 'dart:math';\n",
    ],
    'flutter_core': [
      "// ┌───────────────────────────┐",
      "// │      Flutter Core        │",
      "// └───────────────────────────┘",
      "export 'package:flutter/material.dart' hide RefreshCallback;",
      "export 'package:flutter/cupertino.dart';",
      "export 'package:flutter/widgets.dart';\n",
    ],
    'external': [
      "// ┌───────────────────────────┐",
      "// │     External Packages    │",
      "// └───────────────────────────┘",
    ],
    'ui_components': [
      "// ┌───────────────────────────┐",
      "// │     UI Components       │",
      "// └───────────────────────────┘",
    ],
    'app_core': [
      "// ┌───────────────────────────┐",
      "// │      App Core            │",
      "// └───────────────────────────┘",
    ],
    'features': [
      "// ┌───────────────────────────┐",
      "// │      Features            │",
      "// └───────────────────────────┘",
    ],
    'utils': [
      "// ┌───────────────────────────┐",
      "// │      Utilities           │",
      "// └───────────────────────────┘",
    ]
  };

  // 6. Add external packages
  if (pubspecYaml.containsKey('dependencies')) {
    final dependencies = pubspecYaml['dependencies'] as YamlMap;
    dependencies.keys.forEach((package) {
      if (package != 'flutter' && package is String) {
        exports['external']!.add("export 'package:$package/$package.dart';");
      }
    });
    exports['external']!.add("");
  }

  // 7. Process project files
  void processDirectory(Directory dir) {
    dir.listSync().forEach((entity) {
      if (entity is Directory) {
        if (!excludedDirs.any((dir) => entity.path.endsWith(dir))) {
          processDirectory(entity);
        }
      } else if (entity is File &&
          entity.path.endsWith('.dart') &&
          !excludedFiles.any((ext) => entity.path.endsWith(ext))) {
        final relativePath = path.relative(entity.path, from: libDir.path);
        final exportPath =
            'package:$projectName/${relativePath.replaceAll(r'\', '/')}';

        // Categorize files
        if (relativePath.startsWith('ui/') ||
            relativePath.startsWith('widgets/')) {
          exports['ui_components']!.add("export '$exportPath';");
        } else if (relativePath.startsWith('core/')) {
          if (relativePath.contains('/utils/') ||
              relativePath.contains('/helpers/')) {
            exports['utils']!.add("export '$exportPath';");
          } else {
            exports['app_core']!.add("export '$exportPath';");
          }
        } else if (relativePath.startsWith('features/')) {
          exports['features']!.add("export '$exportPath';");
        } else if (relativePath.startsWith('utils/') ||
            relativePath.startsWith('helpers/')) {
          exports['utils']!.add("export '$exportPath';");
        } else {
          exports['app_core']!.add("export '$exportPath';");
        }
      }
    });
  }

  processDirectory(libDir);

  // 8. Generate the file
  final content = [
    "// GENERATED FILE - DO NOT EDIT",
    "// Main exports file for $projectName\n",
    ...exports['dart_core']!,
    ...exports['flutter_core']!,
    ...exports['external']!,
    ...exports['app_core']!,
    ...exports['utils']!,
    ...exports['ui_components']!,
    ...exports['features']!,
    "\n// Generated by import_generator.dart"
  ].join('\n');

  generatedFile.writeAsStringSync(content);
  print('✅ Generated exports file: ${generatedFile.path}');

  // 9. Format the file
  try {
    Process.runSync('dart', ['format', generatedFile.path]);
    print('🎨 Formatted generated file');
  } catch (e) {
    print('⚠️ Failed to format file: $e');
  }
}
