Pod::Spec.new do |s|
  s.name             = 'my_package_ffi'
  s.version          = '0.0.1'
  s.summary          = 'BLE Scanner FFI plugin'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Author' => 'author@example.com' }
  s.source           = { :path => '.' }
  s.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
end
