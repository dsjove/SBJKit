import SwiftUI

//TODO: have flags to apply various transforms
public struct CroppingModifier: ViewModifier {
	public let state: CroppingState
	public let crop: CGRect?

	public func body(content: Content) -> some View {
		let transformed = content
			.scaleEffect(state.scale)
			.rotationEffect(state.rotation)
			.scaleEffect(x: state.flipX ? -1 : 1, y: state.flipY ? -1 : 1)
			.offset(state.offset)
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
	func croppingStyle(_ state: CroppingState, _ crop: CGRect? = nil) -> some View {
		self.modifier(CroppingModifier(state: state, crop: crop))
	}
}

public extension Image {
	@MainActor func croppingStyle(_ state: CroppingState, _ crop: CGRect? = nil) -> some View {
		self
			.resizable()
			.modifier(CroppingModifier(state: state, crop: crop))
	}
}
