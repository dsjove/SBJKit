import SwiftUI

public struct ImageGeometry {
	/*
		Unit CGRect for initial clip
		Initial scale (anchor on center)

		Translation
		Scale anchored on translation
		Rotation anchored on translation



	 */
	public var scale: CGSize = .init(width: 1, height: 1)
	public var offset: CGSize = .zero
	public var rotation: Double = 0
	public var flipX: Bool = false
	public var flipY: Bool = false
	public var skewX: CGFloat = 0
	public var skewY: CGFloat = 0
	
	public var cropRect: CGRect?
	//TODO: Alignment enum
	public var contentMode: ContentMode = .fit

	public mutating func prime(imageSize: CGSize, targetRect: CGRect) {
		guard imageSize.width > 0 && imageSize.height > 0 else { return }

		let imageAspect = imageSize.width / imageSize.height
		let targetAspect = targetRect.width / targetRect.height

		let scaleFactor: CGFloat
		switch contentMode {
		case .fit:
			scaleFactor = imageAspect > targetAspect
				? targetRect.width / imageSize.width
				: targetRect.height / imageSize.height
		case .fill:
			scaleFactor = imageAspect < targetAspect
				? targetRect.width / imageSize.width
				: targetRect.height / imageSize.height
		}

		scale = CGSize(width: scaleFactor, height: scaleFactor)

		let scaledSize = CGSize(width: imageSize.width * scaleFactor,
								height: imageSize.height * scaleFactor)
		let dx = (targetRect.width - scaledSize.width) / 2 + targetRect.origin.x
		let dy = (targetRect.height - scaledSize.height) / 2 + targetRect.origin.y

		offset = CGSize(width: dx, height: dy)

		if let crop = cropRect {
			offset.width -= crop.origin.x * scale.width
			offset.height -= crop.origin.y * scale.height
		}
	}
}
