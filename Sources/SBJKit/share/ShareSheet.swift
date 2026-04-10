#if !os(watchOS)
import SwiftUI

public struct ShareSheet: UIViewControllerRepresentable {
	let activityItems: [Any]
	let applicationActivities: [UIActivity]?

	public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
		self.activityItems = activityItems
		self.applicationActivities = applicationActivities
	}

	public func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
	}

	public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
