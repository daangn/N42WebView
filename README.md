# N42WebView

[![CI Status](http://img.shields.io/travis/n42corp/N42WebView.svg?style=flat)](https://travis-ci.org/n42corp/N42WebView)
[![Version](https://img.shields.io/cocoapods/v/N42WebView.svg?style=flat)](http://cocoapods.org/pods/N42WebView)
[![License](https://img.shields.io/cocoapods/l/N42WebView.svg?style=flat)](http://cocoapods.org/pods/N42WebView)
[![Platform](https://img.shields.io/cocoapods/p/N42WebView.svg?style=flat)](http://cocoapods.org/pods/N42WebView)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

N42WebView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "N42WebView"
```

## Author

ChangHoon Jung, iamseapy@gmail.com

## License

N42WebView is available under the MIT license. See the LICENSE file for more info.

## Info

// form submit is not request with header
// because WKWebView NSURLRequest body is nil.
// - WKWebView ignores NSURLRequest body : https://forums.developer.apple.com/thread/18952
// - Bug 145410 [WKWebView loadRequest:] ignores HTTPBody in POST requests : https://bugs.webkit.org/show_bug.cgi?id=145410
