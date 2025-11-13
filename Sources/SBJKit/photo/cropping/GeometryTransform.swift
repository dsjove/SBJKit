import SwiftUI

public protocol GeometryTransform {
	var scale: CGFloat { get } //TODO: x and y
	var rotation: Angle { get }
	var flipX: Bool { get }
	var flipY: Bool { get }
	var offset: CGSize { get }
	var crop: CGRect { get }
	//TODO: Perspective skew x and y
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
