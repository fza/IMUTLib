Pod::Spec.new do |s|
  s.name         = "IMUT"
  s.version      = "0.1.0"
  s.summary      = "IMUT is a library for Mobile Usability and User Experience testing."
  s.description  = "Records videos of the screen and the front camera plus captures and logs all sorts of sensoric data as well as application data in real time."
  s.license      = { :type => "proprietary", :file => "LICENSE" }
  s.author       = { "Felix Zandanel" => "felix@zandanel.me" }

  s.platform     = :ios, "7.0"

  s.source_files = "IMUT.framework/Versions/A/Headers/*.h"
  s.resources    = "IMUT.framework/Versions/A/Resources/*"

  s.framework = "AVFoundation"
  s.framework = "UIKit"
  s.framework = "CoreGraphics"
  s.framework = "CoreVideo"
  s.framework = "ImageIO"
  s.framework = "Foundation"

  s.requires_arc = true
  s.xcconfig = {
    "OTHER_LDFLAGS"          => "-ObjC -dynamic",
    "FRAMEWORK_SEARCH_PATHS" => "\"$(PODS_ROOT)/IMUT\""
  }
end
