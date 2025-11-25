import SwiftUI

public struct PlaceholderTextEditor<Placeholder: View>: View {
	@Binding var text: String
	let placeholder: Placeholder
	let numberOfLines: Int

	@State private var showSheet = false

	public init(@ViewBuilder _ placeholder: () -> Placeholder, text: Binding<String>, numberOfLines: Int = 3) {
		self._text = text
		self.numberOfLines = numberOfLines
		self.placeholder = placeholder()
	}

	public init(_ placeholder: String, text: Binding<String>, numberOfLines: Int = 3) where Placeholder == Text {
		self._text = text
		self.numberOfLines = numberOfLines
		self.placeholder = Text(placeholder)
	}

	public var body: some View {
		ZStack(alignment: .topLeading) {
			//TODO: if num lines < 0 present as trailing truncated readonly text
			TextEditor(text: $text)
				.frame(height: estimatedHeight)
				.padding(.trailing, 32)
				.overlay(
					RoundedRectangle(cornerRadius: 8)
						.stroke(Color.secondary.opacity(0.3), lineWidth: 1)
				)
			if text.isEmpty {
				placeholder
					.padding(.horizontal, 4)
					.padding(.vertical, 8)
					.allowsHitTesting(false)
					.foregroundColor(.secondary)
			}
			HStack {
				Spacer()
				Button {
					showSheet = true
				} label: {
					Image(systemName: "square.and.pencil")
						.foregroundColor(.blue)
				}
				.padding(.trailing, 8)
				.padding(.top, 8)
			}
		}
		.sheet(isPresented: $showSheet) {
			NavigationStack {
				TextEditor(text: $text)
					.padding()
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.stroke(Color.secondary.opacity(0.3), lineWidth: 1)
					)
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .principal) {
							placeholder
						}
						ToolbarItem(placement: .navigationBarTrailing) {
							Button("Done") {
								showSheet = false
							}
						}
					}
			}
		}
	}

	private var estimatedHeight: CGFloat {
		let lineHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight
		return lineHeight * CGFloat(numberOfLines) + 16
	}
}
