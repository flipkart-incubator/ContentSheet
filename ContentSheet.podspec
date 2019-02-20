
Pod::Spec.new do |s|

# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.name         = "ContentSheet"
s.version      = "0.2-beta-7"
s.summary      = "A simple control that enables presenting any view controller or any other object that can provide a view like an ActionSheet"

s.description  = <<-DESC
ContentSheet enables presenting any content in an ActionSheet.
The content provider has to follow 'ContentSheetContentProtocol'.
Extensions for UIViewController and UINavigationController have been added in the pod itself so that comes right out of the box.
It is also possible to have the content expand or collapse based on collapsed height and expanded height.
If there is a scrollview and you'd like to expand or collapse the content seemlessly on scroll, that is also possible.
You could customize the background and whether the sheet should be dismissed on tapping outside content or not.
Callbacks are given for all the events as well. Both 'ContentSheetContentProtocol' and 'ContentSheetDelegate' get
callbacks for different events.

Checkout the example in the code.
DESC

s.homepage     = "https://github.com/flipkart-incubator/ContentSheet"


# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }


# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.author             = { "rajatgupta26" => "rajatkumargupta89@gmail.com" }


# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.platform     = :ios, "8.0"


# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.source       = { :git => "https://github.com/flipkart-incubator/ContentSheet.git", :tag => s.version.to_s }


# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.source_files  = "ContentSheet/Classes", "ContentSheet/Classes/**/*.{h,m,swift}"
s.exclude_files = "Classes/Exclude"


end
