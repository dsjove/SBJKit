import SwiftUI

public struct ShareSheet: UIViewControllerRepresentable {
	public var activityItems: [Any]
	public var applicationActivities: [UIActivity]? = nil

	public static func item(content: String, name: String? = nil, ext: String? = nil) -> Any {
		if let name {
			let suffix = ext.map { $0.isEmpty ? "" : ".\($0)" } ?? ""
			let fileName = name.sanitizeFileName() + suffix
			if let fileURL = URL.writeToTempFile(named: fileName, content: content) {
				return fileURL
			}
		}
		return content
	}

	public func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
	}

	public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
