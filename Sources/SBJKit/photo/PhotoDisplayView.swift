import SwiftUI
import UIKit

public protocol PhotoDisplayable: AnyObject {
	associatedtype DiplayView: View
	var uiImage: UIImage? { get set }
	@ViewBuilder
	var displayView: DiplayView { get }
}

public struct PhotoDisplayView<Item: PhotoDisplayable>: View {
	let item: Item
	let showMenu: Bool
	@State private var editingImage: IdentifiableImage?
	@State private var viewingImage: IdentifiableImage?

	public init(item: Item, showMenu: Bool = true) {
		self.item = item
		self.showMenu = showMenu
	}

	public var body: some View {
		ZStack(alignment: .topTrailing) {
			let uiImage = item.uiImage
			if let uiImage, showMenu {
				item.displayView
					.onTapGesture {
						viewingImage = IdentifiableImage(image: uiImage)
					}
			} else {
				item.displayView
			}
			if showMenu {
				PhotoImportMenu(image: Binding {
					item.uiImage
				} set: { newImage in
					if let newImage { // imported or editing
						editingImage = IdentifiableImage(image: newImage)
					} else { // clear
						item.uiImage = nil
					}
				})
				.padding(6)
				.background(
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(.thinMaterial)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.stroke(.secondary.opacity(0.2), lineWidth: 1)
				)
				.shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
				.padding(8)
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 12))
		.fullScreenCover(item: $editingImage) { identifiable in
			PhotoEditSheet(image: identifiable.image) { result in
				if let cropped = result {
					item.uiImage = cropped
				} // else canceled
			}
			dismiss: {
				editingImage = nil
			}
		}
		.fullScreenCover(item: $viewingImage) { identifiable in
			PhotoEditSheet(viewing: identifiable.image) {
				viewingImage = nil
			}
		}
	}
}

