import SwiftUI
import UIKit
import SBJFoundation

public typealias ExportPayload = Identified<[URL]>

public struct DocumentExportView: UIViewControllerRepresentable {
	let urls: [URL]

	public init(urls: [URL]) {
		self.urls = urls
	}

	public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		UIDocumentPickerViewController(forExporting: urls, asCopy: true)
	}

	public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
	}
}
