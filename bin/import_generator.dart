import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

void main() {
  final projectDir = Directory.current;
  final libDir = Directory(path.join(projectDir.path, 'lib'));

  if (!libDir.existsSync()) {
    print('❌ Error: lib directory not found');
    return;
  }

  final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found');
    return;
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspecYaml = loadYaml(pubspecContent);
  final projectName = pubspecYaml['name'];

  // 3. Read import_generator.yaml config
  final configFile = File(path.join(projectDir.path, 'import_generator.yaml'));
  final List<String> excludedPathsFromConfig = [];
  final List<String> excludedPackages = [];

  if (configFile.existsSync()) {
    final configContent = loadYaml(configFile.readAsStringSync());

    if (configContent is YamlMap) {
      if (configContent.containsKey('exclude_paths')) {
        final paths = configContent['exclude_paths'];
        if (paths is YamlList) {
          excludedPathsFromConfig.addAll(paths.map((e) => e.toString()));
        }
      }

      if (configContent.containsKey('exclude_packages')) {
        final pkgs = configContent['exclude_packages'];
        if (pkgs is YamlList) {
          excludedPackages.addAll(pkgs.map((e) => e.toString()));
        }
      }
    }
  }

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

  final generatedFile =
      File(path.join(libDir.path, 'core', 'all_exports.dart'));
  generatedFile.parent.createSync(recursive: true);

  final exports = {
    'dart_core': [
      "// ┌───────────────────────────┐",
      "// │       Dart Core           │",
      "// └───────────────────────────┘",
      "export 'dart:async';",
      "export 'dart:convert';",
      "export 'dart:math';\n",
    ],
    'flutter_core': [
      "// ┌───────────────────────────┐",
      "// │      Flutter Core         │",
      "// └───────────────────────────┘",
      "export 'package:flutter/material.dart' hide RefreshCallback;",
      "export 'package:flutter/cupertino.dart';",
      "export 'package:flutter/widgets.dart';\n",
    ],
    'external': [
      "// ┌───────────────────────────┐",
      "// │     External Packages     │",
      "// └───────────────────────────┘",
    ],
    'ui_components': [
      "// ┌───────────────────────────┐",
      "// │      UI Components        │",
      "// └───────────────────────────┘",
    ],
    'app_core': [
      "// ┌───────────────────────────┐",
      "// │        App Core           │",
      "// └───────────────────────────┘",
    ],
    'features': [
      "// ┌───────────────────────────┐",
      "// │        Features           │",
      "// └───────────────────────────┘",
    ],
    'utils': [
      "// ┌───────────────────────────┐",
      "// │        Utilities          │",
      "// └───────────────────────────┘",
    ]
  };

  // 7. Add external packages
  if (pubspecYaml.containsKey('dependencies')) {
    final dependencies = pubspecYaml['dependencies'] as YamlMap;
    dependencies.keys.forEach((package) {
      if (package != 'flutter' &&
          package is String &&
          !excludedPackages.contains(package)) {
        exports['external']!.add("export 'package:$package/$package.dart';");
      }
    });
    exports['external']!.add(""); // spacing
  }

  // 8. Process Dart files
  void processDirectory(Directory dir) {
    dir.listSync().forEach((entity) {
      final relativePath = path.relative(entity.path, from: libDir.path);
      final posixPath = relativePath.replaceAll(r'\', '/');

      final isExcludedByConfig = excludedPathsFromConfig.any((pattern) {
        if (pattern.contains('**')) {
          final regex = RegExp('^' + pattern.replaceAll('**', '.*') + r'$');
          return regex.hasMatch(posixPath);
        }
        return posixPath.startsWith(pattern);
      });

      if (isExcludedByConfig) {
        if (entity is Directory || entity is File) return;
      }

      if (entity is Directory) {
        processDirectory(entity);
      } else if (entity is File &&
          entity.path.endsWith('.dart') &&
          !excludedFiles.any((ext) => entity.path.endsWith(ext)) &&
          path.basename(entity.path) != 'all_exports.dart') {
        final exportPath = 'package:$projectName/$posixPath';

        if (posixPath.startsWith('ui/') || posixPath.startsWith('widgets/')) {
          exports['ui_components']!.add("export '$exportPath';");
        } else if (posixPath.startsWith('core/')) {
          if (posixPath.contains('/utils/') ||
              posixPath.contains('/helpers/')) {
            exports['utils']!.add("export '$exportPath';");
          } else {
            exports['app_core']!.add("export '$exportPath';");
          }
        } else if (posixPath.startsWith('features/')) {
          exports['features']!.add("export '$exportPath';");
        } else if (posixPath.startsWith('utils/') ||
            posixPath.startsWith('helpers/')) {
          exports['utils']!.add("export '$exportPath';");
        } else {
          exports['app_core']!.add("export '$exportPath';");
        }
      }
    });
  }

  processDirectory(libDir);

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
    "\n// Generated by import_generator"
  ].join('\n');

  generatedFile.writeAsStringSync(content);
  print('✅ Generated exports file: ${generatedFile.path}');

  try {
    Process.runSync('dart', ['format', generatedFile.path]);
    print('🎨 Formatted generated file');
  } catch (e) {
    print('⚠️ Failed to format file: $e');
  }
}
