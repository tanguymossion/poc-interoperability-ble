import Flutter
import UIKit

public class MyPackageFfiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Plugin FFI - pas de method channel nécessaire
    // Les bindings CoreBluetooth sont utilisés directement via FFI
  }
}

