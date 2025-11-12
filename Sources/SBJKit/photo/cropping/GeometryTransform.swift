import SwiftUI

public protocol GeometryTransform {
	var scale: CGFloat { get } //TODO: x and y
	var rotation: Angle { get }
	var flipX: Bool { get }
	var flipY: Bool { get }
	var offset: CGSize { get }
	// var crop: CGRect? { get }
	//TODO: Perspective skew x and y
}

public struct GeometryTransformModifier: ViewModifier {
	public let transform: any GeometryTransform
	public let crop: CGRect?

	public func body(content: Content) -> some View {
		let transformed = content
			.scaleEffect(transform.scale)
			.rotationEffect(transform.rotation)
			.scaleEffect(x: transform.flipX ? -1 : 1, y: transform.flipY ? -1 : 1)
			.offset(transform.offset)
		if let crop {
			transformed
				.aspectRatio(contentMode: .fit)
				.frame(width: crop.width, height: crop.height)
		} else {
			transformed
		}
	}
}

public extension View {
	func geometryEffect(_ transform: any GeometryTransform, _ crop: CGRect? = nil) -> some View {
		self.modifier(GeometryTransformModifier(transform: transform, crop: crop))
	}
}

public extension Image {
	@MainActor func geometryEffect(_ transform: any GeometryTransform, _ crop: CGRect? = nil) -> some View {
		self
			.resizable()
			.modifier(GeometryTransformModifier(transform: transform, crop: crop))
	}
}
