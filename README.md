# FKWidgetSheet

[![CI Status](http://img.shields.io/travis/rajatgupta26/FKWidgetSheet.svg?style=flat)](https://travis-ci.org/rajatgupta26/FKWidgetSheet)
[![Version](https://img.shields.io/cocoapods/v/FKWidgetSheet.svg?style=flat)](http://cocoapods.org/pods/FKWidgetSheet)
[![License](https://img.shields.io/cocoapods/l/FKWidgetSheet.svg?style=flat)](http://cocoapods.org/pods/FKWidgetSheet)
[![Platform](https://img.shields.io/cocoapods/p/FKWidgetSheet.svg?style=flat)](http://cocoapods.org/pods/FKWidgetSheet)

# Demo
![Demo](/Example/Demo/WidgetSheetDemo.gif?raw=true)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

FKWidgetSheet is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "FKWidgetSheet"
```

## Usage

FKWidgetSheet can present any object that conforms to 'FKWidgetSheetContentProtocol'.
UIViewController and UINavigationController extensions are provided out of the box.
Take a look at them in 'FKWidgetSheet.swift' file to get an idea.


To present a view controller or a navigation controller from any view controller

```swift
<present instance>.present(inWidgetSheet: <view controller instance>, animated: true)
```

To dismiss the action sheet from content view controller

```swift
self.dismissWidgetSheet(animated: true)
```

To provide a scroll view to observe from a view controller

```swift
override func scrollViewToObserve(containedIn widgetSheet: FKWidgetSheet) -> UIScrollView? {
    return table
}
```

Control collapsed and expanded heights using

```swift
open func collapsedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat {
    return <height>
}

open func expandedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat {
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

###FKWidgetSheetDelegate

Use delegate to get callbacks. Delegate conforms to 'FKWidgetSheetDelegate'.

These callbacks are sent when sheet is shown or hidden.

```swift
@objc optional func widgetSheetWillShow(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetDidShow(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetWillHide(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetDidHide(_ sheet: FKWidgetSheet)
```

These callbacks are given when widget sheet view appears or disappears.
Use them if you'd wanna update some thing in content on appearance transitions.

```swift
@objc optional func widgetSheetWillAppear(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetDidAppear(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetWillDisappear(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetDidDisappear(_ sheet: FKWidgetSheet)
```
###FKWidgetSheetContentProtocol

Return a content view using this from content controller

```swift
var view: UIView! {get}
```

Prepare for content view lifecycle events using these (Checkout UIViewController extension in 'FKWidgetSheet.swift')

```swift
@objc optional func widgetSheetWillAddContent(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetDidAddContent(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetWillRemoveContent(_ sheet: FKWidgetSheet)
@objc optional func widgetSheetDidRemoveContent(_ sheet: FKWidgetSheet)
```

Configure behaviour using these (Checkout 'SecondViewController.swift' and UIViewController extension in 'FKWidgetSheet.swift')

```swift
@objc optional func collapsedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat
@objc optional func expandedHeight(containedIn widgetSheet: FKWidgetSheet) -> CGFloat

@objc optional func scrollViewToObserve(containedIn widgetSheet: FKWidgetSheet) -> UIScrollView?
```

To know content and state use these readonly vars
```swift
public var content: FKWidgetSheetContentProtocol
public var state
```

Example of presenting any content

```swift
let widgetSheet = FKWidgetSheet(content: <FKWidgetSheetContentProtocol instance>)
<presenter instance>.present(widgetSheet, animated: true, completion: completion)
```



## Author

rajatgupta26, rajat.g@flipkart.com

## License

FKWidgetSheet is available under the MIT license. See the LICENSE file for more info.
