import SwiftUI

//TODO: Combine these efforts

struct FocusedHighlightModifier: ViewModifier {
	@FocusState private var isFocused: UUID?
	let id = UUID()
	let cornerRadius: Double
	let lineThickness: Double

	func body(content: Content) -> some View {
		content
			.focused($isFocused, equals: id)
			.overlay(
				RoundedRectangle(cornerRadius: cornerRadius)
					.inset(by: cornerRadius / -2.0)
					.stroke(
						Color.accentColor,
						lineWidth: isFocused == id ? lineThickness : 0)
					.shadow(color:
						Color.accentColor.opacity(0.25),
						radius: isFocused == id ? 5 : 0)
			)
	}
}

struct BindingFocusedHighlightModifier<Value: Hashable>: ViewModifier {
	var isFocused: FocusState<Value>.Binding
	let id: Value
	let cornerRadius: Double
	let lineThickness: Double

	func body(content: Content) -> some View {
		content
			.focused(isFocused, equals: id)
			.overlay(
				RoundedRectangle(cornerRadius: cornerRadius)
					.stroke(
						Color.accentColor.opacity(0.5),
						lineWidth: isFocused.wrappedValue == id ? lineThickness : 0)
					.shadow(color:
						Color.accentColor.opacity(0.25),
						radius: isFocused.wrappedValue == id ? 5 : 0)
					
			)
	}
}

public extension View {
	func focusedHighlight(cornerRadius: Double = 6.0, lineThickness: Double = 2.0) -> some View {
		self.modifier(FocusedHighlightModifier(cornerRadius: cornerRadius, lineThickness: lineThickness))
	}

	func focusedHighlight(isFocused: FocusState<UUID?>.Binding, id: UUID, cornerRadius: Double = 6.0, lineThickness: Double = 2.0) -> some View {
		self.modifier(BindingFocusedHighlightModifier(isFocused: isFocused, id: id, cornerRadius: cornerRadius, lineThickness: lineThickness))
	}
}
