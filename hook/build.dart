import 'package:hooks/hooks.dart';

/// Build hook pour le package my_package_ffi.
///
/// Ce package utilise :
/// - JNI (jnigen) pour Android - pas de compilation native nécessaire
/// - FFI (ffigen) pour iOS - compilation via CocoaPods
///
/// Ce hook est requis par la configuration ffiPlugin mais ne fait rien.
void main(List<String> args) async {
  await build(args, (input, output) async {
    // Rien à compiler - JNI et FFI sont gérés autrement
  });
}
