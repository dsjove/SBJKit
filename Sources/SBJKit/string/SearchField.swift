import SwiftUI

public struct SearchField<S: SearchProtocol>: View {
	private let titleKey: LocalizedStringKey
	@Binding private var searching: S

	public init(_ titleKey: LocalizedStringKey = "Search", searching: Binding<S>) {
		self.titleKey = titleKey
		self._searching = searching
	}

	public var body: some View {
		TextField(titleKey, text: $searching.text)
			.autocapitalization(.none)
			.disableAutocorrection(true)
			.padding(8)
			.background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
			.overlay(
				RoundedRectangle(cornerRadius: 10)
					.stroke(
						searching.isEmpty ? Color(.separator) : Color.accentColor,
						lineWidth: searching.isEmpty ? 0 : 2)
			)
	}
}
