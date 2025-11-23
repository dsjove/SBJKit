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

private struct _ConditionalMinHeight: ViewModifier {
    let minHeight: Double?
    func body(content: Content) -> some View {
        if let minHeight {
            content.frame(minHeight: minHeight)
        } else {
            content
        }
    }
}
