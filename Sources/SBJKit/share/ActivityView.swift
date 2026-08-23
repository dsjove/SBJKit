import SwiftUI

public typealias SharePayload = Identified<[URL]>

public struct ActivityView: UIViewControllerRepresentable {
	let activityItems: [Any]

	public init(activityItems: [Any]) {
		self.activityItems = activityItems
	}

	public func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
	}

	public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
	}
}
