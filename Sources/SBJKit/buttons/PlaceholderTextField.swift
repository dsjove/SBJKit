import SwiftUI

public struct PlaceholderTextField<Label: View>: View {
	@Binding var text: String
	let label: Label

	public init(_ placeHolder : String, text: Binding<String>) where Label == Text {
		self._text = text
		self.label = Text(placeHolder)
	}

	public var body: some View {
		ZStack {
			if text.isEmpty {
				label
					.foregroundColor(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.top, 0)
					.padding(.leading, 5)
			}
			TextEditor(text: $text)
		}
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.secondary.opacity(0.3), lineWidth: 1)
		)
	}
}
