//
//  N42WebViewController.swift
//  Pods
//
//  Created by ChangHoon Jung on 2015. 12. 17..
//
//

import UIKit
import WebKit

public class N42WebViewController: UIViewController {
    lazy var webView: WKWebView = {
        var webViewTmp = self.webViewConfiguration == nil ?
            WKWebView() : WKWebView(frame: CGRectZero, configuration: self.webViewConfiguration!)
        webViewTmp.navigationDelegate = self
        webViewTmp.UIDelegate = self
        return webViewTmp
    }()
    
    lazy var backButton: UIBarButtonItem = {
        return UIBarButtonItem(image: self.loadImageFromBundle("back"), style: .Plain, target: self, action: Selector("touchBackButton"))
    }()
    
    lazy var fowardButton: UIBarButtonItem = {
        return UIBarButtonItem(image: self.loadImageFromBundle("forward"), style: .Plain, target: self, action: Selector("touchFowardButton"))
    }()
    
    lazy var refreshButton: UIBarButtonItem = {
        var button = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: Selector("touchRefreshButton"))
        return button
    }()
    
    lazy var stopButton: UIBarButtonItem = {
        var button = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: Selector("touchStopButton"))
        return button
    }()
    
    lazy var actionButton: UIBarButtonItem = {
        var button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("touchActionButton"))
        return button
    }()
    
    lazy var progressView: UIProgressView = {
        var progressView = UIProgressView(progressViewStyle: .Default)
        return progressView
    }()
    
    
    public var webViewConfiguration: WKWebViewConfiguration?
    public var request: NSURLRequest?
    public var headers: [String: String]?
    public var allowHosts: [String]?
    public var decidePolicyForNavigationActionHandler: ((webView: WKWebView, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) -> Void)?
    
    public var hideToolbar: Bool = false
    public var toolbarStyle: UIBarStyle?
    public var toolbarTintColor: UIColor?
    public var actionUrl: NSURL?
    public var navTitle: String?
    public var progressViewTintColor: UIColor?
    
    public required convenience init(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
    }
    
    public init(url: String) {
        self.request = NSURLRequest(URL: NSURL(string: url) ?? NSURL())
        super.init(nibName: nil, bundle: nil)
    }
    
    public init(request: NSURLRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        removeProgressViewObserver()
    }
    
    private func loadImageFromBundle(name: String) -> UIImage? {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("N42WebView", ofType: "bundle")
        return UIImage(named: name, inBundle: NSBundle(path: path ?? ""), compatibleWithTraitCollection: nil)
    }
}

extension N42WebViewController {
    public func loadRequest() {
        if let request = request {
            if let requestWithHeader = requestWithHeadersAllowHosts(request) {
                webView.loadRequest(requestWithHeader)
            } else {
                webView.loadRequest(request)
            }
        }
    }
    
    func requestWithHeadersAllowHosts(request: NSURLRequest) -> NSURLRequest? {
        guard let host = request.URL?.host where (allowHosts?.contains(host) ?? false) else {
            return nil
        }
        if let headers = headers {
            let mutableRequest: NSMutableURLRequest? = request.mutableCopy() as? NSMutableURLRequest
            for (key, value) in headers {
                mutableRequest?.setValue(value, forHTTPHeaderField: key)
            }
            return mutableRequest
        }
        return nil
    }

}

extension N42WebViewController {
    public override func loadView() {
        view = webView
        loadRequest()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshToolbarItems()
        appendProgressView()
        if let navTitle = navTitle {
            navigationItem.title = navTitle
        }
    }

    public override func viewDidLayoutSubviews() {
        progressView.frame = CGRectMake(0, topLayoutGuide.length, view.frame.size.width, 0.5)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(hideToolbar, animated: true)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

// ProgressView
extension N42WebViewController {
    func appendProgressView() {
        view.addSubview(progressView)
        if let progressViewTintColor = progressViewTintColor {
            progressView.tintColor = progressViewTintColor
        }
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    func removeProgressViewObserver() {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "estimatedProgress" {
            progressView.hidden = webView.estimatedProgress == 1
            let progress: Float = progressView.hidden ? 0.0 : Float(webView.estimatedProgress)
            progressView.setProgress(progress, animated: true)
        }
    }
}

// Toolbar Action
extension N42WebViewController {
    func touchBackButton() {
        webView.goBack()
    }
    
    func touchFowardButton() {
        webView.goForward()
    }
    
    func touchRefreshButton() {
        webView.reload()
    }
    
    func touchStopButton() {
        webView.stopLoading()
        refreshToolbarItems()
    }
    
    func touchActionButton() {
        var tmpUrl = webView.URL
        if let actionUrl = actionUrl {
            tmpUrl = actionUrl
        }
        
        guard let url = tmpUrl else {
            return
        }

        if url.absoluteString.hasPrefix("file:///") {
            let docController = UIDocumentInteractionController(URL: url)
            docController.presentOptionsMenuFromRect(view.bounds, inView: view, animated: true)
        } else {
            let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            presentViewController(activityController, animated: true, completion: nil)
        }
    }
}

// Refresh UI
extension N42WebViewController {
    func refreshToolbarItems() {
        if hideToolbar {
            return
        }
        
        backButton.enabled = webView.canGoBack
        fowardButton.enabled = webView.canGoForward
        
        let refreshOrStopButton = webView.loading ? stopButton : refreshButton
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

        toolbarItems = [
            fixedSpace, backButton,
            flexibleSpace, fowardButton,
            flexibleSpace, refreshOrStopButton,
            flexibleSpace, actionButton
        ]
        
        if let toolbarStyle = toolbarStyle {
            navigationController?.toolbar.barStyle = toolbarStyle
        }
        
        if let toolbarTintColor = toolbarTintColor {
            navigationController?.toolbar.tintColor = toolbarTintColor
        }
    }
}

extension N42WebViewController: WKNavigationDelegate {
    public func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        refreshToolbarItems()
    }
    
    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        refreshToolbarItems()
        
        if navTitle == nil {
            navigationItem.title = webView.title
        }
    }
    
    public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        refreshToolbarItems()
    }
    
    public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let handler = decidePolicyForNavigationActionHandler {
            handler(webView: webView, navigationAction: navigationAction, decisionHandler: decisionHandler)
        } else if let url = navigationAction.request.URL {
            let httpSchemes = ["http", "https"]
            let app = UIApplication.sharedApplication()
            if !httpSchemes.contains(url.scheme) && app.canOpenURL(url) {
                app.openURL(url)
                decisionHandler(.Cancel)
                return
            }
            
            // form submit is not request with header
            // because WKWebView NSURLRequest body is nil.
            // - WKWebView ignores NSURLRequest body : https://forums.developer.apple.com/thread/18952
            // - Bug 145410 [WKWebView loadRequest:] ignores HTTPBody in POST requests : https://bugs.webkit.org/show_bug.cgi?id=145410
            if navigationAction.navigationType == .LinkActivated
                || navigationAction.navigationType == .BackForward
                || navigationAction.navigationType == .Reload
            {
                if let request = requestWithHeadersAllowHosts(navigationAction.request) {
                    webView.loadRequest(request)
                    decisionHandler(.Cancel)
                    return
                }
            }
            decisionHandler(.Allow)
        } else {
            decisionHandler(.Allow)
        }
    }
}

extension N42WebViewController: WKUIDelegate {
    public func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Why is WKWebView not opening links with target=“_blank” http://stackoverflow.com/a/25853806/397457
        let requestHandler = { (request: NSURLRequest) in
            if !(navigationAction.targetFrame?.mainFrame ?? false) {
                webView.loadRequest(request)
            }
        }
        
        if let request = requestWithHeadersAllowHosts(navigationAction.request) {
            requestHandler(request)
        } else {
            requestHandler(navigationAction.request)
        }
        
        return nil
    }
}