#if !os(watchOS)
import SwiftUI
import QuickLook

final class PreviewItem: NSObject, QLPreviewItem {
	let url: URL
	init(url: URL) { self.url = url }

	var previewItemURL: URL? { url }
	var previewItemTitle: String? { url.lastPathComponent }
}

struct DocumentPreviewController: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: Context) -> QLPreviewController {
		let controller = QLPreviewController()
		controller.dataSource = context.coordinator
		return controller
	}

	func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) { }

	func makeCoordinator() -> Coordinator {
		Coordinator(url: url)
	}

	final class Coordinator: NSObject, QLPreviewControllerDataSource {
		let item: PreviewItem

		init(url: URL) {
			self.item = PreviewItem(url: url)
		}

		func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
			1
		}

		func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
			item
		}
	}
}

struct DocumentPreviewSheet: View {
	@Environment(\.dismiss) private var dismiss
	let url: URL
	let title: String?

	init(url: URL, title: String? = nil) {
		self.url = url
		self.title = title ?? url.lastPathComponent
	}

	var body: some View {
		NavigationStack {
			DocumentPreviewController(url: url)
				.navigationTitle(title ?? "")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						DismissButton {
							dismiss()
						}
						.keyboardShortcut(.cancelAction)
					}
				}
		}
		.interactiveDismissDisabled()
	}
}
#endif
