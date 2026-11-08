import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    var webView: WKWebView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // Отключаем 300ms задержку тапа в iOS и системное выделение текста
        let touchScript = WKUserScript(
            source: """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            document.documentElement.style.webkitTouchCallout = 'none';
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(touchScript)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.03, green: 0.05, blue: 0.08, alpha: 1.0)

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadLocalApp()
    }

    func loadLocalApp() {
        let bundleURL = Bundle.main.bundleURL

        let candidatePaths = [
            bundleURL.appendingPathComponent("www").appendingPathComponent("index.html"),
            bundleURL.appendingPathComponent("index.html")
        ]

        for fileURL in candidatePaths {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                webView.loadFileURL(fileURL, allowingReadAccessTo: bundleURL)
                return
            }
        }

        if let fallbackURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(fallbackURL, allowingReadAccessTo: bundleURL)
        }
    }
}
