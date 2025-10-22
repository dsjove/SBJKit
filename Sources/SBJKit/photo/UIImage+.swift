import UIKit
import Foundation

public struct IdentifiableImage: Identifiable {
	public let id = UUID()
	public let image: UIImage

	public init(image: UIImage) {
		self.image = image
	}
}

public extension UIImage {
	convenience init?(data: Data?) {
		guard let data = data else {
			return nil
		}
		self.init(data: data)
	}

	func shrinkTo(_ targetSize: CGSize) -> UIImage {
		if self.size.width <= targetSize.width && self.size.height <= targetSize.height {
			return self
		}

		let widthRatio = targetSize.width / size.width
		let heightRatio = targetSize.height / size.height
		let scaleFactor = min(widthRatio, heightRatio)

		// Compute scaled size that fits inside targetSize
		let scaledSize = CGSize(
			width: size.width * scaleFactor,
			height: size.height * scaleFactor
		)

		let renderer = UIGraphicsImageRenderer(size: scaledSize)
		return renderer.image { _ in
			self.draw(in: CGRect(origin: .zero, size: scaledSize))
		}
	}
}
