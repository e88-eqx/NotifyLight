Pod::Spec.new do |spec|
  spec.name         = "NotifyLight"
  spec.version      = "1.0.0"
  spec.summary      = "Lightweight iOS SDK for NotifyLight self-hosted notifications"
  spec.description  = <<-DESC
    NotifyLight iOS SDK provides a simple, privacy-focused way to integrate 
    push notifications and in-app messages with your NotifyLight server.
    
    Features:
    - Direct APNs integration without Firebase dependencies
    - In-app message support with automatic queueing
    - Modern Swift async/await APIs
    - Comprehensive privacy controls
    - Zero-config initialization
  DESC

  spec.homepage     = "https://github.com/notifylight/notifylight"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "NotifyLight" => "hello@notifylight.com" }
  spec.source       = { :git => "https://github.com/notifylight/notifylight.git", :tag => "#{spec.version}" }

  spec.ios.deployment_target = "13.0"
  spec.swift_version = "5.5"

  spec.source_files = "Sources/NotifyLight/**/*.swift"
  spec.resource_bundles = {
    'NotifyLight' => ['Sources/NotifyLight/PrivacyInfo.xcprivacy']
  }

  spec.frameworks = "Foundation", "UserNotifications", "UIKit"
  
  spec.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.5'
  }
end