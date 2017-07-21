#
#  Be sure to run `pod spec lint FKWidgetSheet.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.name         = "FKWidgetSheet"
s.version      = "0.1.0"
s.summary      = "A simple control that enables presenting any view controller or navigation controller or any other object that can provide a view like an ActionSheet"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
s.description  = <<-DESC
FKWidgetSheet enables presenting any content in an ActionSheet.
The content provider has to follow 'FKWidgetSheetContentProtocol'.
Extensions for UIViewController and UINavigationController have been added in the pod itself so that comes right out of the box.
It is also possible to have the content expand or collapse based on collapsed height and expanded height.
If there is a scrollview and you'd like to expand or collapse the content seemlessly on scroll, that is also possible.
You could customize the background and whether the sheet should be dismissed on tapping outside content or not.
Callbacks are given for all the events as well. Both 'FKWidgetSheetContentProtocol' and 'FKWidgetSheetDelegate' get
callbacks for different events.

Checkout the example in the code.
DESC

s.homepage     = "https://github.com/rajatgupta26/FKWidgetSheet"
# s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Licensing your code is important. See http://choosealicense.com for more info.
#  CocoaPods will detect a license file if there is a named LICENSE*
#  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
#

s.license      = { :type => "MIT", :file => "LICENSE" }


# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the authors of the library, with email addresses. Email addresses
#  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
#  accepts just a name if you'd rather not provide an email address.
#
#  Specify a social_media_url where others can refer to, for example a twitter
#  profile URL.
#

s.author             = { "rajatgupta26" => "rajatkumargupta89@gmail.com" }

# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  If this Pod runs only on iOS or OS X, then specify the platform and
#  the deployment target. You can optionally include the target after the platform.
#

s.platform     = :ios, "8.0"

# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the location from where the source should be retrieved.
#  Supports git, hg, bzr, svn and HTTP.
#

s.source       = { :git => "https://github.com/rajatgupta26/FKWidgetSheet.git", :branch => "master" }


# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

s.source_files  = "FKWidgetSheet/Classes", "FKWidgetSheet/Classes/**/*.{h,m,swift}"
s.exclude_files = "Classes/Exclude"


# ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
# s.resources = "Resources/*.png"

# s.preserve_paths = "FilesToSave", "MoreFilesToSave"


end
