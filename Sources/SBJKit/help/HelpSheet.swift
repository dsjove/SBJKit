import SwiftUI
import UIKit
import WebKit
import ObjectiveC

fileprivate enum ScrollState {
	case none
	case atTop
	case atBottom
	case scrolling
}

public struct HelpSheet: View {
	@Environment(\.dismiss) private var dismiss

	public let asset: AssetPath
	public let substitutions: [String: String]
	public let showAbout: Bool

	@State private var scrollState = ScrollState.none
	@StateObject private var webViewScroller = HelpWebViewScroller()

	public var body: some View {
		NavigationStack {
			ZStack(alignment: .bottomTrailing) {
				HelpWebView(asset: asset, substitutions: substitutions, scrollState: $scrollState, scroller: webViewScroller)
					.navigationBarTitle(asset.title, displayMode: .inline)
					.toolbar {
						ToolbarItemGroup(placement: .topBarLeading) {
							DismissButton {
								dismiss()
							}
						}
						if showAbout {
							ToolbarItemGroup(placement: .topBarTrailing) {
								HelpButton(
									asset: AssetPath(title: "About", folder: "help", mainBundle: true),
									systemImage: "",
									auto: true,
									showAbout: false)
							}
						}
					}
				if scrollState != .none {
					Button(action: {
						webViewScroller.scrollPage(down: scrollState != .atBottom)
					}) {
						ScrollableIndicatorView(isAtBottom: scrollState == .atBottom)
							.padding(12)
					}
				}
			}
		}
	}
}

@MainActor
fileprivate class HelpWebViewScroller: ObservableObject {
	private(set) weak var webView: WKWebView?

	func setWebView(_ webView: WKWebView) { self.webView = webView }

	func scrollPage(down: Bool) {
		guard let scrollView = webView?.scrollView else { return }
		let pageHeight = scrollView.frame.height
		let y = down ? min(scrollView.contentOffset.y + pageHeight, scrollView.contentSize.height - scrollView.frame.height) : 0
		scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
	}
}

fileprivate struct ScrollableIndicatorView: View {
	let isAtBottom: Bool
	var body: some View {
		ZStack {
			Circle()
				.stroke(Color.primary.opacity(0.5))
				.frame(width: 32, height: 32)
			Image(systemName: isAtBottom ? "chevron.up.2" : "chevron.down")
				.font(.system(size: 16, weight: .semibold))
				.foregroundColor(Color.primary.opacity(0.5))
		}
		.shadow(radius: 1)
	}
}

fileprivate struct HelpWebView: UIViewRepresentable {
	public let asset: AssetPath
	var substitutions: [String: String] = [:]
	@Binding var scrollState: ScrollState
	var scroller: HelpWebViewScroller

	private class StateHolder {
		var lastLoadedAsset: AssetPath?
		var lastLoadedSubstitutionsHash: Int?
	}
	private static var stateKey: UInt8 = 0

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func makeUIView(context: Context) -> WKWebView {
		let webView = WKWebView()
		webView.scrollView.addObserver(context.coordinator, forKeyPath: "contentSize", options: [.new, .initial], context: nil)
		webView.scrollView.addObserver(context.coordinator, forKeyPath: "frame", options: [.new, .initial], context: nil)
		scroller.setWebView(webView)
		let state = StateHolder()
		objc_setAssociatedObject(webView, &HelpWebView.stateKey, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return webView
	}

	func updateUIView(_ uiView: WKWebView, context: Context) {
		guard let state = objc_getAssociatedObject(uiView, &HelpWebView.stateKey) as? StateHolder else { return }
		let substitutionsHash = substitutions.hashValue
		if asset != state.lastLoadedAsset || substitutionsHash != state.lastLoadedSubstitutionsHash {
			if let htmlString = asset.stringValue()  {
				let allSubstitutions = substitutions.merging(
					extractImageSubstitutions(from: htmlString)) { (_, new) in new }
				let corrected = htmlString.replacingOccurrences(using: allSubstitutions)
				uiView.loadHTMLString(corrected, baseURL: nil)
			} else {
				let errorHTML = "<html><body style='display:flex;align-items:center;justify-content:center;height:100vh;margin:0;font-family:-apple-system,sans-serif;'><div style='font-size:2.5em;font-weight:bold;text-align:center;padding-left:16pt;padding-right:16pt;'>Our apologies.<p></p><p></p>We could not find help for this part of the application.</div></body></html>"
				uiView.loadHTMLString(errorHTML, baseURL: nil)
			}
			state.lastLoadedAsset = asset
			state.lastLoadedSubstitutionsHash = substitutionsHash
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
				uiView.scrollView.flashScrollIndicators()
			}
		}
	}

	static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
		uiView.scrollView.removeObserver(coordinator, forKeyPath: "contentSize")
		uiView.scrollView.removeObserver(coordinator, forKeyPath: "frame")
	}

	private func extractImageSubstitutions(from html: String) -> [String: String] {
		var results: [String: String] = [:]
		let patterns: [(String, Bool, String)] = [
			("SF_([a-zA-Z0-9.]+)", false, "SF_"),
			("AS_([a-zA-Z0-9.\\-_]+)", true, "AS_")
		]
		for (pattern, isAsset, prefix) in patterns {
			if let regex = try? NSRegularExpression(pattern: pattern) {
				let range = NSRange(html.startIndex..<html.endIndex, in: html)
				let matches = regex.matches(in: html, range: range)
				for match in matches {
					guard match.numberOfRanges == 2, let range = Range(match.range(at: 1), in: html) else { continue }
					let imageName = String(html[range])
					let key = prefix + imageName
					if let base64 = encodeImage(imageName, isAsset) {
						results[key] = base64
					}
				}
			}
		}
		return results
	}

	private func encodeImage(_ imageName: String, _ isAsset: Bool) -> String? {
		let image: UIImage?
		if isAsset {
			image = UIImage(named: imageName)
		}
		else {
			let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
			image = UIImage(systemName: imageName, withConfiguration: config)
		}
		guard let image else { return nil }
		let renderer = UIGraphicsImageRenderer(size: image.size)
		let img = renderer.image { context in
			UIColor(named: "AccentColor")?.setFill()
			context.cgContext.translateBy(x: 0, y: image.size.height)
			context.cgContext.scaleBy(x: 1, y: -1)
			context.cgContext.setBlendMode(.normal)
			let rect = CGRect(origin: .zero, size: image.size)
			context.cgContext.clip(to: rect, mask: image.cgImage!)
			context.cgContext.fill(rect)
		}
		let base64 = img.pngData()?.base64EncodedString()
		guard let base64 else { return nil }
		return "<img src='data:image/png;base64,\(base64)' alt='\(imageName)' style='vertical-align:middle;max-width:1.2em;max-height:1.2em;'/>"
	}

	@MainActor class Coordinator: NSObject {
		var parent: HelpWebView

		init(_ parent: HelpWebView) {
			self.parent = parent
		}

		override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
			guard let scrollView = object as? UIScrollView else { return }
			if keyPath == "contentSize" || keyPath == "frame" {
				DispatchQueue.main.async {
					let offset = scrollView.contentOffset.y
					let height = scrollView.frame.size.height
					let contentHeight = scrollView.contentSize.height
					let scrollState: ScrollState
					if scrollView.contentSize.height <= scrollView.frame.size.height + 1 {
						scrollState = .none
					}
					else if offset + height >= contentHeight - 1 {
						scrollState = .atBottom
					}
					else if offset <= 1 {
						scrollState = .atTop
					}
					else {
						scrollState = .scrolling
					}
					if self.parent.scrollState != scrollState {
						self.parent.scrollState = scrollState
					}
				}
			}
		}
	}
}
