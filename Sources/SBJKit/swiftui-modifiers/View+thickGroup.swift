import SwiftUI
import SBJFoundation

private struct ThickGroupModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.padding(.horizontal, 8)
			.padding(.vertical, 6)
			.background(
				ProcessInfo.isRunningOnAnyMac ? AnyShapeStyle(Color.white.opacity(0.9)) : AnyShapeStyle(.regularMaterial),
				in: RoundedRectangle(cornerRadius: 12, style: .continuous)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.strokeBorder(.separator.opacity(0.6))
			)
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
}

public extension View {
	func thickGroup() -> some View {
		modifier(ThickGroupModifier())
	}
}
