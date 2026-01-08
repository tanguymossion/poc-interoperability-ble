Pod::Spec.new do |s|
  s.name             = 'my_package_ffi'
  s.version          = '0.0.1'
  s.summary          = 'BLE Scanner using FFI for iOS'
  s.description      = <<-DESC
A Flutter FFI package for BLE scanning on iOS using CoreBluetooth.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your@email.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '12.0'
  
  # Flutter framework
  s.dependency 'Flutter'
  
  # Sources: Plugin Swift + Objective-C trampolines générés par ffigen
  # Le fichier .m DOIT être compilé pour que les symboles FFI soient disponibles
  s.source_files = 'Classes/**/*', '../lib/src/ios/corebluetooth_bindings.dart.m'
  
  # Framework CoreBluetooth
  s.frameworks = 'CoreBluetooth', 'Foundation'
  
  # Configuration du compilateur pour ARC (requis par le fichier .m)
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'CLANG_ENABLE_MODULES' => 'YES',
    'CLANG_ENABLE_OBJC_ARC' => 'YES'
  }
  
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
end
