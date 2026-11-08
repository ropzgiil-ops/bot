import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var webView: WKWebView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.07, alpha: 1.0)
        setupWebView()
        loadLocalApp()
    }

    func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "nativeHaptic")
        contentController.add(self, name: "nativeSaveState")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // CRITICAL FOR IPHONE 11: Persistent Data Store (NEVER cleared on tab/app close)
        config.websiteDataStore = WKWebsiteDataStore.default()

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.07, alpha: 1.0)

        view.addSubview(webView)
    }

    func loadLocalApp() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "www") else {
            // Fallback to bundle root
            if let rootPath = Bundle.main.path(forResource: "index", ofType: "html") {
                let url = URL(fileURLWithPath: rootPath)
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
            return
        }
        let url = URL(fileURLWithPath: htmlPath)
        let wwwDir = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: wwwDir)
    }

    // Native Bridge Handlers
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "nativeHaptic" {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } else if message.name == "nativeSaveState", let jsonString = message.body as? String {
            saveToDocumentsDirectory(jsonString: jsonString)
        }
    }

    func saveToDocumentsDirectory(jsonString: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDirectory.appendingPathComponent("ironlog_database.json")
        try? jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
