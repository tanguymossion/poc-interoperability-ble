import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Build hook pour my_package_ffi.
///
/// Compile le fichier Objective-C généré par ffigen (corebluetooth_bindings.dart.m)
/// en une dylib pour iOS/macOS.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final codeConfig = input.config.code;
    final os = codeConfig.targetOS;

    // Seulement iOS et macOS pour CoreBluetooth
    if (os != OS.iOS && os != OS.macOS) return;

    final builder = CBuilder.library(
      name: 'my_package_ffi',
      assetName: 'my_package_ffi.dylib',
      sources: ['lib/src/ios/corebluetooth_bindings.dart.m'],
      flags: ['-fobjc-arc'],
      frameworks: ['CoreBluetooth', 'Foundation'],
      language: Language.objectiveC,
    );

    await builder.run(
      input: input,
      output: output,
      logger: Logger('')..level = Level.WARNING,
    );
  });
}
