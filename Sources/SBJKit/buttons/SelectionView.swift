import SwiftUI
import SwiftData

public struct SelectionView<Element: Identifiable, Label: View>: View {
	@Environment(\.dismiss) private var dismiss

	var title: String
	let noun: String
	let elements: (String)->[Element]?
	let enabled: (Element) -> Bool
	let onSelect: (Element?) -> Void
	let allowNilSelection: Bool
	let label: (Element) -> Label
	let initId: Element.ID?

	@State private var selected: Element?
	@State private var searchText: String = ""

	public init(
		title: String? = nil,
		noun: String,
		elements: @escaping (String) -> [Element]?,
		enabled: @escaping (Element) -> Bool = { _ in true },
		selection: Binding<Element?>,
		@ViewBuilder label: @escaping (Element) -> Label
	) {
		self = .init(
			title: title,
			noun: noun,
			elements: elements,
			enabled: enabled,
			initial: selection.wrappedValue,
			onSelect: { selection.wrappedValue = $0! },
			allowNilSelection: true,
			label: label
		)
	}

	public init(
		title: String? = nil,
		noun: String,
		elements: @escaping (String) -> [Element]?,
		enabled: @escaping (Element) -> Bool = { _ in true },
		selection: Binding<Element>,
		@ViewBuilder label: @escaping (Element) -> Label
	) {
		self = .init(
			title: title,
			noun: noun,
			elements: elements,
			enabled: enabled,
			initial: selection.wrappedValue,
			onSelect: { selection.wrappedValue = $0! },
			allowNilSelection: false,
			label: label
		)
	}

	public init(
		title: String? = nil,
		noun: String,
		elements: @escaping (String) -> [Element]?,
		enabled: @escaping (Element) -> Bool = { _ in true },
		initial selection: Element? = nil,
		onSelect: @escaping (Element) -> Void,
		@ViewBuilder label: @escaping (Element) -> Label
	) {
		self = .init(
			title: title,
			noun: noun,
			elements: elements,
			enabled: enabled,
			initial: selection,
			onSelect: { onSelect($0!) },
			allowNilSelection: false,
			label: label
		)
	}

	public init(
		title: String? = nil,
		noun: String,
		elements: @escaping (String) -> [Element]?,
		enabled: @escaping (Element) -> Bool = { _ in true },
		initial selection: Element? = nil,
		onSelect: @escaping (Element?) -> Void,
		allowNilSelection: Bool = true,
		@ViewBuilder label: @escaping (Element) -> Label
	) {
		self.title = title ?? "Select a \(noun.capitalized)"
		self.noun = noun
		self.elements = elements
		self.enabled = enabled
		self.onSelect = onSelect
		self.allowNilSelection = allowNilSelection
		self.label = label
		self._selected = State(initialValue: selection)
		self.initId = selection?.id
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
								SelectionListRowView(
									element: element,
									isInit: element.id == initId,
									enabled: enabled,
									selected: $selected) {
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
					.disabled(!allowNilSelection && selected == nil)
				}
			}
		}
	}

	struct SelectionListRowView: View {
		let element: Element
		let isInit: Bool
		let enabled: Bool
		@Binding var selected: Element?
		let label: () -> Label

		private var isSelected: Bool { selected?.id == element.id }

		var body: some View {
			HStack {
				if isInit {
					Image(systemName: "circle.fill")
						.imageScale(.small)
				}
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
			.onTapGesture {
				if enabled {
					selected = selected?.id == element.id ? nil : element
				}
			}
		}
	}
}

