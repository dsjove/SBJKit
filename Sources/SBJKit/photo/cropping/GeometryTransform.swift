import SwiftUI

public protocol GeometryTransform {
	var scale: CGFloat { get }
	var rotation: Angle { get }
	var flipX: Bool { get }
	var flipY: Bool { get }
	var offset: CGSize { get }
	var crop: CGRect { get }
	//TODO: Perspective skew x and y
}

public extension GeometryTransform {
	 func render(_ image: UIImage) -> UIImage {
		let cropRect = crop
		let renderSize = CGSize(width: max(1, cropRect.width), height: max(1, cropRect.height))

		let imgSize = image.size

		// Scale the image to fit entirely within the crop rect while preserving aspect ratio
		let scaleToFit = min(renderSize.width / imgSize.width, renderSize.height / imgSize.height)
		let w = imgSize.width * scaleToFit * scale
		let h = imgSize.height * scaleToFit * scale

		// Center the image within the crop rect and then apply offset
		let x = (renderSize.width - w) / 2 + offset.width
		let y = (renderSize.height - h) / 2 + offset.height

		// Compute center for rotation and flipping transforms
		let centerX = x + w / 2
		let centerY = y + h / 2

		let renderer = UIGraphicsImageRenderer(size: renderSize)
		return renderer.image { ctx in
			ctx.cgContext.setFillColor(UIColor.black.cgColor)
			ctx.cgContext.fill(CGRect(origin: .zero, size: renderSize))

			// Apply transforms around the image center
			ctx.cgContext.translateBy(x: centerX, y: centerY)
			if flipX { ctx.cgContext.scaleBy(x: -1, y: 1) }
			if flipY { ctx.cgContext.scaleBy(x: 1, y: -1) }
			ctx.cgContext.rotate(by: CGFloat(rotation.radians))
			ctx.cgContext.translateBy(x: -centerX, y: -centerY)

			image.draw(in: CGRect(x: x, y: y, width: w, height: h))
		}
	}
}

private struct ConditionalClip: ViewModifier {
	let clip: Bool
	func body(content: Content) -> some View {
		if clip {
			content.clipped()
		} else {
			content
		}
	}
}

public struct GeometryTransformModifier: ViewModifier {
	public let transform: any GeometryTransform
	public let clip: Bool

	public func body(content: Content) -> some View {
		let transformed = content
			.scaleEffect(transform.scale)
			.rotationEffect(transform.rotation)
			.scaleEffect(x: transform.flipX ? -1 : 1, y: transform.flipY ? -1 : 1)
			.offset(transform.offset)
		transformed
			.aspectRatio(contentMode: .fit)
			.frame(width: transform.crop.width, height: transform.crop.height)
			.modifier(ConditionalClip(clip: clip))
	}
}

public extension View {
	func geometryEffect(_ transform: any GeometryTransform, clip: Bool) -> some View {
		self.modifier(GeometryTransformModifier(transform: transform, clip: clip))
	}
}

public extension Image {
	@MainActor func geometryEffect(_ transform: any GeometryTransform, clip: Bool) -> some View {
		self
			.resizable()
			.modifier(GeometryTransformModifier(transform: transform, clip: clip))
	}
}
