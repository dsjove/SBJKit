import SwiftUI
import UIKit

final class DocumentOpener: NSObject, UIDocumentInteractionControllerDelegate {
	private var controller: UIDocumentInteractionController?

	func open(url: URL, from viewController: UIViewController) {
		controller = UIDocumentInteractionController(url: url)
		controller?.delegate = self
		controller?.presentOptionsMenu(from: viewController.view.bounds, in: viewController.view, animated: true)
	}
}

struct DocumentOpenerHost: UIViewControllerRepresentable {
	let url: URL
	
	func makeUIViewController(context: Context) -> UIViewController {
		let vc = UIViewController()
		DispatchQueue.main.async {
			context.coordinator.opener.open(url: url, from: vc)
		}
		return vc
	}
	
	func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
	
	func makeCoordinator() -> Coordinator {
		Coordinator()
	}
	
	final class Coordinator {
		let opener = DocumentOpener()
	}
}
