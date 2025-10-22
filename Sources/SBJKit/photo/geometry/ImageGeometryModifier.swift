import SwiftUI

@MainActor
public struct ImageGeometryModifier: ViewModifier {
	let geometry: ImageGeometry

	public func body(content: Content) -> some View {
		// Estimate content bounds
//		let w = geometry.cropRect?.width ?? 100
//		let h = geometry.cropRect?.height ?? 100

		// Define warped corners
//		let topLeft     = CGPoint(x: 0 + geometry.skewX, y: 0 + geometry.skewY)
//		let topRight    = CGPoint(x: w - geometry.skewX, y: 0 - geometry.skewY)
//		let bottomRight = CGPoint(x: w + geometry.skewX, y: h + geometry.skewY)
//		let bottomLeft  = CGPoint(x: 0 - geometry.skewX, y: h - geometry.skewY)

//		let warpedQuad = [topLeft, topRight, bottomRight, bottomLeft]

//        let projection = ProjectionTransform(
//            CGAffineTransform.quadrilateralWarp(from: CGRect(x: 0, y: 0, width: w, height: h),
//                                                to: warpedQuad)
//        )

		return content
			.scaleEffect(x: geometry.flipX ? -geometry.scale.width : geometry.scale.width,
						 y: geometry.flipY ? -geometry.scale.height : geometry.scale.height,
						 anchor: .center)
			.rotationEffect(.degrees(geometry.rotation), anchor: .center)
			//.projectionEffect(projection)
			.offset(geometry.offset)
			.ifLet(geometry.cropRect) { view, rect in
				view
					.frame(width: rect.width, height: rect.height)
					.clipped()
			}
	}
}

public extension View {
@MainActor
	func imageGeometry(_ geometry: ImageGeometry) -> some View {
		self.modifier(ImageGeometryModifier(geometry: geometry))
	}

	fileprivate func ifLet<T>(_ value: T?, transform: (Self, T) -> some View) -> some View {
		if let unwrapped = value {
			return AnyView(transform(self, unwrapped))
		} else {
			return AnyView(self)
		}
	}
}

public extension Image {
@MainActor
	func imageGeometry(_ geometry: ImageGeometry) -> some View {
		self.resizable().modifier(ImageGeometryModifier(geometry: geometry))
	}
}
