import SwiftUI

private struct NavigationTitleHighlighted: ViewModifier {
	let alerted: Bool
	let highlighted: Color?

	func body(content: Content) -> some View {
		HStack {
			content
				.font(.headline)
				.italic(alerted)
				.lineLimit(1)
				.truncationMode(.tail)
				.background(
					Group {
						if let highlighted {
							RoundedRectangle(cornerRadius: 8, style: .continuous)
								.fill(highlighted.opacity(0.15))
								.padding(.vertical, -2)
								.padding(.horizontal, -6)
						}
					}
				)
			Spacer()
		}
	}
}

public extension View {
	 func navigationTitle(alerted: Bool = false, highlighted: Color? = nil) -> some View {
		modifier(NavigationTitleHighlighted(alerted: alerted, highlighted: highlighted))
	}
}
