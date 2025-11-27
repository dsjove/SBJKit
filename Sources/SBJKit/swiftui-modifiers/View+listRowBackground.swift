import SwiftUI

public extension View {
	  func listRowBackground<E: Identifiable & Equatable>(
			tag: E,
			selection: Binding<E?>) -> some View {
		self
			.contentShape(Rectangle())
			.onTapGesture { selection.wrappedValue = tag }
			.listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
			.listRowBackground(
				Group {
					if selection.wrappedValue == tag {
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(Color.gray.opacity(0.2))
					} else {
						Color.clear
					}
				}
			)
	}
}

public struct FixedFormListBackground: ViewModifier {
	var cornerRadius: CGFloat = 24

	public func body(content: Content) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.fill(Color(.systemGroupedBackground))
			.padding(.horizontal, 20)
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.stroke(.separator.opacity(0.15), lineWidth: 0.5)
			.padding(.horizontal, 20)
			content
				.scrollContentBackground(.hidden)
				.padding(.horizontal, 20)
				.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		}
	}
}

public extension View {
	func fixedFormListBackground(cornerRadius: CGFloat = 24) -> some View {
		modifier(FixedFormListBackground(cornerRadius: cornerRadius))
	}
}
