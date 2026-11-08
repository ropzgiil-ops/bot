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

        // Инжектим фикс кликов для iOS прямо перед загрузкой DOM
        let touchFixScript = WKUserScript(
            source: """
            (function() {
                var style = document.createElement('style');
                style.innerHTML = '* { -webkit-tap-highlight-color: transparent !important; touch-action: manipulation !important; }';
                document.head.appendChild(style);
                
                // Перенаправляем touchend в моментальный click без ожидания 300мс
                document.addEventListener('touchend', function(e) {
                    var target = e.target.closest('button, a, [role="button"], input, select');
                    if (target) {
                        target.focus();
                    }
                }, {passive: true});
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(touchFixScript)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = true
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
        let candidates = [
            bundleURL.appendingPathComponent("www").appendingPathComponent("index.html"),
            bundleURL.appendingPathComponent("index.html"),
            Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www"),
            Bundle.main.url(forResource: "index", withExtension: "html")
        ].compactMap { $0 }

        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                webView.loadFileURL(url, allowingReadAccessTo: bundleURL)
                return
            }
        }
    }
}
