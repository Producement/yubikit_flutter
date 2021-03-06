#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint yubikit_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'yubikit_flutter'
  s.version          = '0.0.29'
  s.summary          = 'Wrapper for YubiKit iOS and Android SDKs.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/Producement/yubikit_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Producement OÜ' => 'maido@producement.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  s.dependency 'YubiKit', '~> 4.2.0'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
