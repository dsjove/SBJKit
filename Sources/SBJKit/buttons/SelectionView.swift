import SwiftUI
import SwiftData

public struct SelectionView<Element: Identifiable, Label: View>: View {
	@Environment(\.dismiss) private var dismiss

	var title: String
	let noun: String
	let elements: (String)->[Element]?
	let enabled: (Element) -> Bool
	let onSelect: (Element) -> Void
	let label: (Element) -> Label

	@State private var selected: Element? = nil
	@State private var searchText: String = ""

	public init(
		title: String? = nil,
		noun: String,
		elements: @escaping (String) -> [Element]?,
		enabled: @escaping (Element) -> Bool = { _ in true },
		onSelect: @escaping (Element) -> Void,
		@ViewBuilder label: @escaping (Element) -> Label
	) {
		self.title = title ?? "Select a \(noun.capitalized)"
		self.noun = noun
		self.elements = elements
		self.enabled = enabled
		self.onSelect = onSelect
		self.label = label
	}

	public var body: some View {
		NavigationStack {
			VStack(spacing: 8) {
				SearchField(searching: $searchText)
					.padding(.horizontal)
				let elements = elements(searchText)
				if let elements {
					if elements.isEmpty {
						Spacer()
						Text("No \(noun) found.")
						Spacer()
					}
					else {
						List {
							ForEach(elements) { element in
								let enabled = enabled(element)
								SelectionListRowView(element: element, enabled: enabled, selected: $selected) {
									label(element)
								}
							}
						}
					}
				}
				else {
					Spacer()
					Text("No \(noun) available.")
					Spacer()
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle(title)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("OK") {
						if let selected {
							onSelect(selected)
							dismiss()
						}
					}
					.disabled(selected == nil)
				}
			}
		}
	}

	struct SelectionListRowView: View {
		let element: Element
		let enabled: Bool
		@Binding var selected: Element?
		let label: () -> Label

		private var isSelected: Bool { selected?.id == element.id }

		var body: some View {
			HStack {
				label()
				Spacer()
				if selected?.id == element.id {
					Image(systemName: "checkmark")
						.foregroundStyle(.selection)
				}
			}
			.disabled(!enabled)
			.foregroundStyle(enabled ? .primary : .secondary)
			.contentShape(Rectangle())
			.onTapGesture { if enabled { selected = element } }
		}
	}
}
