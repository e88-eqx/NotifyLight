require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name         = "NotifyLight"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  Lightweight React Native SDK for NotifyLight self-hosted notifications.
                  Zero-config push notifications with direct native integration.
                   DESC
  s.homepage     = "https://github.com/notifylight/notifylight-react-native"
  s.license      = "MIT"
  # s.license    = { :type => "MIT", :file => "FILE_LICENSE" }
  s.authors      = { "NotifyLight Team" => "support@notifylight.com" }
  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/notifylight/notifylight-react-native.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,swift}"
  s.requires_arc = true

  s.dependency "React-Core"
  s.frameworks = "UserNotifications"
end