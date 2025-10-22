import SwiftUI
import UIKit

public struct ColorPickerView: UIViewControllerRepresentable {
	private let title: String
	@Binding private var selectedColor: Color

	public init(title: String, selectedColor: Binding<Color>) {
		self.title = title
		self._selectedColor = selectedColor
	}

	public class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
		var parent: ColorPickerView

		init(parent: ColorPickerView) {
			self.parent = parent
		}

		public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {}

		public func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
			parent.selectedColor = Color(uiColor: color)
		}
	}

	public func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}

	public func makeUIViewController(context: Context) -> UIColorPickerViewController {
		let picker = UIColorPickerViewController()
		picker.title = title
		picker.delegate = context.coordinator
		picker.supportsAlpha = true
		if #available(iOS 26.0, *) {
			//picker.supportsEyedropper = false
		}
		picker.selectedColor = UIColor(selectedColor)
		picker.view.backgroundColor = .systemBackground
		return picker
	}

	public func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {}
}
