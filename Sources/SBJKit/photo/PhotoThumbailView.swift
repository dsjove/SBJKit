import SwiftUI
import UIKit
import SwiftData

public struct PhotoThumbailView<Source: PhotoSource>: View {
	var source: Source
	let useThumbnail: Bool
	let size: CGSize

	public init(
			source: Source,
			useThumbnail: Bool = true,
			size: CGSize = .init(width: 44, height: 44)) {
		self.source = source
		self.useThumbnail = useThumbnail
		self.size = size
	}

	public var body: some View {
		PhotoImportMenu(image: Binding {
					source.photoImage
				} set: {
					source.photoImage = $0
				}, options: .all, editImports: true) {
			if useThumbnail && source.hasImage {
				source.thumbnailView(size: size)
			}
			else {
				Image(systemName: "photo")
					.resizable()
					.scaledToFit()
					.frame(width: size.width, height: size.height)
					.clipShape(RoundedRectangle(cornerRadius: 8))
			}
		}
	}
}
