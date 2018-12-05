# ContentSheet

<!--[![CI Status](http://img.shields.io/travis/rajatgupta26/ContentSheet.svg?style=flat)](https://travis-ci.org/rajatgupta26/ContentSheet) -->
[![Version](https://img.shields.io/cocoapods/v/ContentSheet.svg?style=flat)](http://cocoapods.org/pods/ContentSheet)
[![License](https://img.shields.io/cocoapods/l/ContentSheet.svg?style=flat)](http://cocoapods.org/pods/ContentSheet)
[![Platform](https://img.shields.io/cocoapods/p/ContentSheet.svg?style=flat)](http://cocoapods.org/pods/ContentSheet)

# Demo
![Demo](/Example/Demo/WidgetSheetDemo.gif?raw=true)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ContentSheet is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ContentSheet"
```

## Usage

ContentSheet can present any object that conforms to 'ContentSheetContentProtocol'.
Example project and demo show how to present a UIView, UIViewController, UINavigationController or a UIView controller by some custom object/controller.
UIView, UIViewController and UINavigationController extensions are provided out of the box.
Take a look at them in '[ContentSheet.swift](/ContentSheet/Classes/ContentSheet.swift)' file to get an idea.


To present a view controller or a navigation controller from any view controller

```swift
<presenter instance>.present(inContentSheet: <view controller instance>, animated: true)
```

To dismiss the content sheet from content view controller

```swift
self.dismissContentSheet(animated: true)
```

To present a view in content sheet

```swift
let contentSheet = ContentSheet(content: <UIView instance>)
<presenter instance>.present(contentSheet, animated: true, completion: completion)
```

To dismiss content sheet from content view

```swift
self.dismissContentSheet(animated: true)
```

To provide a scroll view to observe from a view controller

```swift
override func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView? {
    return <scrollview instance>
}
```

ContentSheet shows a navigation bar on top of content by default.
To control this behaviour use this property of ContentSheet instance

```swift
public var showDefaultHeader: Bool = true
```

If you present a UIViewController in ContentSheet, default header will take the navigation item of view controller and push that on the default navigation bar's stack.
That means just as in case of UINavigationController, the title and left, right bar buttons of your view controller's navigationItem will show on top by default.
If there is no left bar button, content sheet will show a close button there.

If you are presenting anything other than, UIViewController, use this property from ContentSheetContentProtocol
```swift
@objc optional var navigationItem: UINavigationItem { get }
```

If you need to access the default navigation bar or item, use this property of content sheet instance
```swift
public var contentNavigationBar: UINavigationBar?
public var contentNavigationItem: UINavigationItem?
```
You can customise the navigation item content's with these. Or just disable the default header using ```swift showDefaultHeader``` and make the whole content yourself.

In case a UIViewController instance is presented, this convenience method lets you access the navigation bar on top
```swift
public func cs_navigationBar()
```
This method first checks if the UIViewController instance is inside a navigationController. If so, it'll return navigationController's navigation bar else content sheet's navigation bar 


Control collapsed and expanded heights using

```swift
open func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
    return <height>
}

open func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
    return <height>
}
```

Control status bar appearance using 
```swift
open func prefersStatusBarHidden(contentSheet: ContentSheet) -> Bool {
    return <should hide?>
}

open func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
    return <style>
}

open func preferredStatusBarUpdateAnimation(contentSheet: ContentSheet) -> UIStatusBarAnimation {
    return <animation>
}
```

There are convenience methods on UIViewController and UIView to get content sheet using 'self.contentSheet()'
There is also a function in ContentSheet i.e. 'contentSheet(content:)' that can be used to get content sheet for any content.

Also, take a look at 'presentCustomView(_:)' function in [ViewController.swift](/Example/ContentSheet/ViewController.swift) and [CustomContent.swift](/Example/ContentSheet/CustomContent.swift) to see how to present UIView or it's subclasses.


Use these properties of content sheet to customize behaviour

```swift
public var showDefaultHeader: Bool = true
public var blurBackground: Bool = false
public var blurStyle: UIBlurEffectStyle = .dark
public var dismissOnTouchOutside: Bool = true
public var backgroundImage: UIImage? 
public var backgroundView: UIView? 
```

### ContentSheetDelegate

Use delegate to get callbacks. Delegate conforms to 'ContentSheetDelegate'.

These callbacks are sent when sheet is shown or hidden.

```swift
@objc optional func contentSheetWillShow(_ sheet: ContentSheet)
@objc optional func contentSheetDidShow(_ sheet: ContentSheet)
@objc optional func contentSheetWillHide(_ sheet: ContentSheet)
@objc optional func contentSheetDidHide(_ sheet: ContentSheet)
```

These callbacks are given when content sheet view appears or disappears.
Use them if you'd wanna update some thing in content on appearance transitions.

```swift
@objc optional func contentSheetWillAppear(_ sheet: ContentSheet)
@objc optional func contentSheetDidAppear(_ sheet: ContentSheet)
@objc optional func contentSheetWillDisappear(_ sheet: ContentSheet)
@objc optional func contentSheetDidDisappear(_ sheet: ContentSheet)
```
### ContentSheetContentProtocol

Return a content view using this from content controller

```swift
var view: UIView! {get}
```

Return a navigation item this from content controller
```swift
@objc optional var navigationItem: UINavigationItem { get }
```

Prepare for content view lifecycle events using these (Checkout UIViewController extension in [ContentSheet.swift](/ContentSheet/Classes/ContentSheet.swift))

```swift
@objc optional func contentSheetWillAddContent(_ sheet: ContentSheet)
@objc optional func contentSheetDidAddContent(_ sheet: ContentSheet)
@objc optional func contentSheetWillRemoveContent(_ sheet: ContentSheet)
@objc optional func contentSheetDidRemoveContent(_ sheet: ContentSheet)
```

Configure behaviour using these (Checkout [SecondViewController.swift](/Example/ContentSheet/SecondViewController.swift) and UIViewController extension in [ContentSheet.swift](/ContentSheet/Classes/ContentSheet.swift))

```swift
@objc optional func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat
@objc optional func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat

@objc optional func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView?
```

To know content and state use these readonly vars
```swift
public var content: ContentSheetContentProtocol
public var state
```

Example of presenting any content

```swift
let contentSheet = ContentSheet(content: <ContentSheetContentProtocol instance>)
<presenter instance>.present(contentSheet, animated: true, completion: completion)
```



## Author

rajatgupta26, rajatkumargupta89@gmail.com

## License

Copyright 2017 Flipkart Internet Pvt. Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
