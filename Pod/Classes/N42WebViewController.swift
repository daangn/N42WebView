//
//  N42WebViewController.swift
//  Pods
//
//  Created by ChangHoon Jung on 2015. 12. 17..
//
//

import UIKit
import WebKit

open class N42WebViewController: UIViewController {
    lazy var webView: WKWebView = {
        var webViewTmp = self.webViewConfiguration == nil ?
            WKWebView() : WKWebView(frame: CGRect.zero, configuration: self.webViewConfiguration!)
        webViewTmp.navigationDelegate = self
        webViewTmp.uiDelegate = self
        return webViewTmp
    }()

    lazy var backButton: UIBarButtonItem = {
        return UIBarButtonItem(image: self.loadImageFromBundle("back"), style: .plain, target: self, action: #selector(N42WebViewController.touchBackButton))
    }()

    lazy var fowardButton: UIBarButtonItem = {
        return UIBarButtonItem(image: self.loadImageFromBundle("forward"), style: .plain, target: self, action: #selector(N42WebViewController.touchFowardButton))
    }()

    lazy var refreshButton: UIBarButtonItem = {
        var button = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(N42WebViewController.touchRefreshButton))
        return button
    }()

    lazy var stopButton: UIBarButtonItem = {
        var button = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(N42WebViewController.touchStopButton))
        return button
    }()

    lazy var actionButton: UIBarButtonItem = {
        var button = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(N42WebViewController.touchActionButton))
        return button
    }()

    lazy var progressView: UIProgressView = {
        var progressView = UIProgressView(progressViewStyle: .default)
        return progressView
    }()


    open var webViewConfiguration: WKWebViewConfiguration?
    open var request: URLRequest?
    open var headers: [String: String]?
    open var allowHosts: [String]?
    open var decidePolicyForNavigationActionHandler: ((_ webView: WKWebView, _ navigationAction: WKNavigationAction, _ decisionHandler: (WKNavigationActionPolicy) -> Void) -> Void)?

    open var hideToolbar: Bool = false
    open var toolbarStyle: UIBarStyle?
    open var toolbarTintColor: UIColor?
    open var actionUrl: URL?
    open var navTitle: String?
    open var progressViewTintColor: UIColor?

    public required convenience init(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
    }

    public init(url: String) {
        if let url = URL(string: url) {
            self.request = URLRequest(url: url)
        }

        super.init(nibName: nil, bundle: nil)
    }

    public init(request: URLRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        removeProgressViewObserver()
    }

    fileprivate func loadImageFromBundle(_ name: String) -> UIImage? {
        let path = Bundle(for: type(of: self)).path(forResource: "N42WebView", ofType: "bundle")
        return UIImage(named: name, in: Bundle(path: path ?? ""), compatibleWith: nil)
    }
}

extension N42WebViewController {
    public func loadRequest() {
        if let request = request {
            if let requestWithHeader = requestWithHeadersAllowHosts(request) {
                webView.load(requestWithHeader)
            } else {
                webView.load(request)
            }
        }
    }

    func requestWithHeadersAllowHosts(_ request: URLRequest) -> URLRequest? {
        guard let host = request.url?.host, (allowHosts?.contains(host) ?? false) else {
            return nil
        }
        if let headers = headers {
            let mutableRequest: NSMutableURLRequest? = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest
            for (key, value) in headers {
                mutableRequest?.setValue(value, forHTTPHeaderField: key)
            }
            return mutableRequest as URLRequest?
        }
        return nil
    }

}

extension N42WebViewController {
    open override func loadView() {
        view = webView
        loadRequest()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        refreshToolbarItems()
        appendProgressView()
        if let navTitle = navTitle {
            navigationItem.title = navTitle
        }
    }

    open override func viewDidLayoutSubviews() {
        progressView.frame = CGRect(x: 0, y: topLayoutGuide.length, width: view.frame.size.width, height: 0.5)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(hideToolbar, animated: true)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setToolbarHidden(true, animated: true)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func localize(text: String) -> String {
        guard let path = Bundle(for: type(of: self)).path(forResource: "N42WebView", ofType: "bundle"),
            let bundle = Bundle(path: path) else {
            return text
        }
        return bundle.localizedString(forKey: text, value: text, table: "N42WebView")
    }
}

// ProgressView
extension N42WebViewController {
    func appendProgressView() {
        view.addSubview(progressView)
        if let progressViewTintColor = progressViewTintColor {
            progressView.tintColor = progressViewTintColor
        }
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.new, context: nil)
    }

    func removeProgressViewObserver() {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.isHidden = webView.estimatedProgress == 1
            let progress: Float = progressView.isHidden ? 0.0 : Float(webView.estimatedProgress)
            progressView.setProgress(progress, animated: true)
        }
    }
}

// Toolbar Action
extension N42WebViewController {
    @objc func touchBackButton() {
        webView.goBack()
    }

    @objc func touchFowardButton() {
        webView.goForward()
    }

    @objc func touchRefreshButton() {
        webView.reload()
    }

    @objc func touchStopButton() {
        webView.stopLoading()
        refreshToolbarItems()
    }

    @objc func touchActionButton() {
        var tmpUrl = webView.url
        if let actionUrl = actionUrl {
            tmpUrl = actionUrl
        }

        guard let url = tmpUrl else {
            return
        }

        if url.absoluteString.hasPrefix("file:///") {
            let docController = UIDocumentInteractionController(url: url)
            docController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        } else {
            let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activityController, animated: true, completion: nil)
        }
    }
}

// Refresh UI
extension N42WebViewController {
    func refreshToolbarItems() {
        if hideToolbar {
            return
        }

        backButton.isEnabled = webView.canGoBack
        fowardButton.isEnabled = webView.canGoForward

        let refreshOrStopButton = webView.isLoading ? stopButton : refreshButton
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

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
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        refreshToolbarItems()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        refreshToolbarItems()

        if navTitle == nil {
            navigationItem.title = webView.title
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        refreshToolbarItems()
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let handler = decidePolicyForNavigationActionHandler {
            handler(webView, navigationAction, decisionHandler)
        } else if let url = navigationAction.request.url {
            let httpSchemes = ["http", "https"]
            let app = UIApplication.shared
            if let scheme = url.scheme, !httpSchemes.contains(scheme) && app.canOpenURL(url) {
                app.openURL(url)
                decisionHandler(.cancel)
                return
            }

            // form submit is not request with header
            // because WKWebView NSURLRequest body is nil.
            // - WKWebView ignores NSURLRequest body : https://forums.developer.apple.com/thread/18952
            // - Bug 145410 [WKWebView loadRequest:] ignores HTTPBody in POST requests : https://bugs.webkit.org/show_bug.cgi?id=145410
            if navigationAction.navigationType == .linkActivated
                || navigationAction.navigationType == .backForward
                || navigationAction.navigationType == .reload
            {
                if let request = requestWithHeadersAllowHosts(navigationAction.request) {
                    webView.load(request)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension N42WebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Why is WKWebView not opening links with target=“_blank” http://stackoverflow.com/a/25853806/397457
        let requestHandler = { (request: URLRequest) in
            if !(navigationAction.targetFrame?.isMainFrame ?? false) {
                webView.load(request)
            }
        }

        if let request = requestWithHeadersAllowHosts(navigationAction.request) {
            requestHandler(request)
        } else {
            requestHandler(navigationAction.request)
        }

        return nil
    }

    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let av = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        av.addAction(UIAlertAction(
            title: localize(text: "OK"),
            style: .default,
            handler: { (action) in
                completionHandler()
            }
        ))
        present(av, animated: true, completion: nil)
    }

    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let av = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        av.addAction(UIAlertAction(
            title: localize(text: "OK"),
            style: .default,
            handler: { (action) in
                completionHandler(true)
            }
        ))
        av.addAction(UIAlertAction(
            title: localize(text: "Cancel"),
            style: .cancel,
            handler: { (action) in
                completionHandler(false)
            }
        ))
        present(av, animated: true, completion: nil)
    }

    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let av = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        av.addTextField { (textField) in
            textField.text = defaultText
        }

        av.addAction(UIAlertAction(
            title: localize(text: "OK"),
            style: .default,
            handler: { (action) in
                if let text = av.textFields?.first?.text {
                    completionHandler(text)
                } else {
                    completionHandler(defaultText)
                }
            }
        ))

        av.addAction(UIAlertAction(
            title: localize(text: "Cancel"),
            style: .cancel,
            handler: { (action) in
                completionHandler(nil)
            }
        ))

        present(av, animated: true, completion: nil)
    }
}
