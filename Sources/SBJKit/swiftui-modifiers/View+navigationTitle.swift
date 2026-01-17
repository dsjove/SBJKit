import SwiftUI

private struct NavigationTitleHighlighted: ViewModifier {
	let alerted: Bool

	func body(content: Content) -> some View {
		HStack {
			content
				.font(.headline)
				.italic(alerted)
				.lineLimit(1)
				.truncationMode(.tail)
			Spacer()
		}
	}
}

public extension View {
	 func navigationTitle(alerted: Bool = false) -> some View {
		modifier(NavigationTitleHighlighted(alerted: alerted))
	}
}

public extension View {
	func oneLiner() -> some View {
		self
			.focusedHighlight()
			#if !os(watchOS)
			.textFieldStyle(.roundedBorder)
			#endif
			.multilineTextAlignment(.leading)
			.lineLimit(1)
			.submitLabel(.done)
	}
}
