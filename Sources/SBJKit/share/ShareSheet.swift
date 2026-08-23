#if !os(watchOS)
import SwiftUI

//NOTE: share sheets really want to work with URLs

public struct ShareSheet: UIViewControllerRepresentable {
	let activityItems: [Any]
	let applicationActivities: [UIActivity]?
	let dismissed: (()->())?

	public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, dismissed: (()->())? = nil) {
		self.activityItems = activityItems
		self.applicationActivities = applicationActivities
		self.dismissed = dismissed
	}

	public func makeUIViewController(context: Context) -> UIActivityViewController {
		let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		controller.completionWithItemsHandler = { _, _, _, _ in
			DispatchQueue.main.async {
				dismissed?()
			}
		}
		return controller
	}

	public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
	}
}
#endif
