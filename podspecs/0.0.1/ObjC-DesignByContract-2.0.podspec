Pod::Spec.new do |s|
  s.platform     = :ios, "5.0"

  s.name         = "ObjC-DesignByContract-2.0"
  s.version      = "0.0.1"
  s.summary      = "Macros for implementing design-by-contract architecture into Objective-C programs."
  s.homepage     = "http://github.com/brynbellomy/ObjC-DesignByContract-experimental-2.0"
  s.license      = "LICENSE.md"
  s.author       = { "Bryn Austin Bellomy" => "bryn.bellomy@gmail.com" }

  s.source       = { :git => "https://github.com/brynbellomy/ObjC-DesignByContract-experimental-2.0.git" }
  s.source_files = "{ObjC-DesignByContract.h,Contracts/*.{m,h}}"

  s.requires_arc = true
  s.prefix_header_contents = "#import <ObjC-DesignByContract-2.0/ObjC-DesignByContract.h>\n#import <CocoaLumberjack/DDLog.h>\nstatic const int ddLogLevel = LOG_FLAG_ERROR | LOG_FLAG_INFO;"

  s.xcconfig = { "PUBLIC_HEADERS_FOLDER_PATH" => "include/$(TARGET_NAME)" }

  s.dependency "MAObjCRuntime"
  s.dependency "BrynKit"
  s.dependency "CocoaLumberjack"
end
