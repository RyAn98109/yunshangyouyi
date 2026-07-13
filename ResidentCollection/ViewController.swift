import UIKit
import WebKit

// MARK: - PaddingLabel (用于 Toast 内边距)

private class PaddingLabel: UILabel {
    var padding = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}

// MARK: - ViewController

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var splashView: UIView!
    private var logoView: SplashLogoView!

    /// 主色 #1E5F8E
    private let primaryColor = UIColor(red: 30/255, green: 95/255, blue: 142/255, alpha: 1)

    // MARK: - 状态栏 & 方向

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = primaryColor
        setupWebView()
        setupSplashScreen()
        loadPage()
    }

    // MARK: - WebView 配置

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true

        // 允许 localStorage / DOM Storage
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        // JS 桥接
        let contentController = WKUserContentController()

        // 注入 window.Android 桥接脚本，与 Android 端接口一致
        let bridgeScript = """
        window.Android = {
            saveExcelFile: function(base64Data, fileName) {
                window.webkit.messageHandlers.saveExcelFile.postMessage({
                    base64Data: base64Data,
                    fileName: fileName
                });
            },
            showToast: function(message) {
                window.webkit.messageHandlers.showToast.postMessage({
                    message: message
                });
            }
        };
        """
        let userScript = WKUserScript(
            source: bridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)

        contentController.add(self, name: "saveExcelFile")
        contentController.add(self, name: "showToast")

        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1)
        webView.isOpaque = false

        // 禁止缩放
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Splash 启动封面

    private func setupSplashScreen() {
        splashView = UIView()
        splashView.backgroundColor = primaryColor
        splashView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splashView)

        logoView = SplashLogoView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        splashView.addSubview(logoView)

        NSLayoutConstraint.activate([
            splashView.topAnchor.constraint(equalTo: view.topAnchor),
            splashView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splashView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            logoView.widthAnchor.constraint(equalToConstant: 120),
            logoView.heightAnchor.constraint(equalToConstant: 120),
            logoView.centerXAnchor.constraint(equalTo: splashView.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: splashView.centerYAnchor),
        ])
    }

    // MARK: - 加载页面

    private func loadPage() {
        // index.html 和 xlsx.full.min.js 均在 Bundle 根目录
        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            let directoryURL = htmlURL.deletingLastPathComponent()
            webView.loadFileURL(htmlURL, allowingReadAccessTo: directoryURL)
        }
    }

    // MARK: - 移除 Splash

    private func removeSplash() {
        guard splashView != nil, splashView.superview != nil else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.splashView.alpha = 0
            },
            completion: { _ in
                self.splashView.removeFromSuperview()
                self.splashView = nil
                self.logoView = nil
            }
        )
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        removeSplash()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        removeSplash()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        removeSplash()
    }
}

// MARK: - WKScriptMessageHandler (JS 桥接)

extension ViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "saveExcelFile":
            handleSaveExcelFile(message.body)
        case "showToast":
            handleShowToast(message.body)
        default:
            break
        }
    }

    /// 保存 Excel 文件 — 对应 Android 端 saveExcelFile(base64Data, fileName)
    private func handleSaveExcelFile(_ body: Any) {
        guard let dict = body as? [String: String],
              let base64Data = dict["base64Data"],
              let fileName = dict["fileName"],
              let data = Data(base64Encoded: base64Data)
        else {
            DispatchQueue.main.async {
                self.showToast("❌ 保存失败: 数据解码错误")
            }
            return
        }

        // 写入 Documents 目录
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            DispatchQueue.main.async {
                self.showToast("✅ 文件已保存: \(fileName)")
                self.presentShareSheet(for: fileURL)
            }
        } catch {
            DispatchQueue.main.async {
                self.showToast("❌ 保存失败: \(error.localizedDescription)")
            }
        }
    }

    /// 显示 Toast — 对应 Android 端 showToast(message)
    private func handleShowToast(_ body: Any) {
        guard let dict = body as? [String: String], let message = dict["message"] else { return }
        DispatchQueue.main.async {
            self.showToast(message)
        }
    }

    // MARK: - 分享面板

    private func presentShareSheet(for fileURL: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        present(activityVC, animated: true)
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        // 移除已有 Toast
        view.subviews.forEach { sub in
            if sub is PaddingLabel { sub.removeFromSuperview() }
        }

        let toastLabel = PaddingLabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.layer.cornerRadius = 8
        toastLabel.layer.masksToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.alpha = 0
        toastLabel.numberOfLines = 0

        view.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            toastLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -100
            ),
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])

        UIView.animate(withDuration: 0.2) {
            toastLabel.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    toastLabel.alpha = 0
                },
                completion: { _ in
                    toastLabel.removeFromSuperview()
                }
            )
        }
    }
}

// MARK: - SplashLogoView (启动封面 Logo)

private class SplashLogoView: UIView {
    /// 房屋图标颜色 #3D7CB8
    private let houseColor = UIColor(red: 61/255, green: 124/255, blue: 184/255, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.masksToBounds = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 将 120×120 坐标系缩放到实际 rect
        let scaleX = rect.width / 120
        let scaleY = rect.height / 120
        context.scaleBy(x: scaleX, y: scaleY)

        // 绘制房屋轮廓（与 Android splash_logo.xml 路径一致）
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 60, y: 25))     // 屋顶顶点
        path.addLine(to: CGPoint(x: 25, y: 52))   // 左屋顶
        path.addLine(to: CGPoint(x: 25, y: 92))   // 左墙底

        // 左下圆角
        path.addCurve(
            to: CGPoint(x: 29, y: 96),
            controlPoint1: CGPoint(x: 25, y: 94.2),
            controlPoint2: CGPoint(x: 26.8, y: 96)
        )

        path.addLine(to: CGPoint(x: 45, y: 96))   // 门左下
        path.addLine(to: CGPoint(x: 45, y: 70))   // 门左上
        path.addLine(to: CGPoint(x: 75, y: 70))   // 门右上
        path.addLine(to: CGPoint(x: 75, y: 96))   // 门右下
        path.addLine(to: CGPoint(x: 91, y: 96))   // 右墙底

        // 右下圆角
        path.addCurve(
            to: CGPoint(x: 95, y: 92),
            controlPoint1: CGPoint(x: 93.2, y: 96),
            controlPoint2: CGPoint(x: 95, y: 94.2)
        )

        path.addLine(to: CGPoint(x: 95, y: 52))   // 右屋顶
        path.close()

        houseColor.setFill()
        path.fill()
    }
}
