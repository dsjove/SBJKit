import UIKit

#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
public extension URL {
	var isValidURL: Bool {
		guard !self.absoluteString.isEmpty else { return false }
		#if !WIDGET_TARGET
		return UIApplication.shared.canOpenURL(self)
		#else
		return true
		#endif
	}

	@discardableResult
	static func open(_ urlString: String) -> URL? {
		let url = URL(string: urlString)
		open(url)
		return url
	}

	static func open(_ url: URL?) {
		guard let url else { return }
		url.open()
	}

	func open() {
		#if os(watchOS)
			WKExtension.shared().openSystemURL(self)
		#elseif os(iOS)
			#if !WIDGET_TARGET
				UIApplication.shared.open(self, options: [:], completionHandler: nil)
			#endif
		#elseif os(macOS)
			NSWorkspace.shared.open(self)
		#endif
	}

	static func writeToTempFile(named: String, content: String) -> URL? {
		let tempDir = FileManager.default.temporaryDirectory
		//let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let fileURL = tempDir.appendingPathComponent(named)
		do {
			try content.write(to: fileURL, atomically: true, encoding: .utf8)
			return fileURL
		} catch {
			return nil
		}
	}
}
