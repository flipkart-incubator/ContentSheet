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
UIViewController and UINavigationController extensions are provided out of the box.
Take a look at them in '[ContentSheet.swift](/ContentSheet/Classes/ContentSheet.swift)' file to get an idea.


To present a view controller or a navigation controller from any view controller

```swift
<presenter instance>.present(inContentSheet: <view controller instance>, animated: true)
```

To dismiss the action sheet from content view controller

```swift
self.dismissContentSheet(animated: true)
```

To provide a scroll view to observe from a view controller

```swift
override func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView? {
    return <scrollview instance>
}
```

Control collapsed and expanded heights using

```swift
open func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
    return <height>
}

open func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
    return <height>
}
```

Use these to customize behaviour

```swift
public var blurBackground: Bool = true
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

ContentSheet is available under the MIT license. See the LICENSE file for more info.

