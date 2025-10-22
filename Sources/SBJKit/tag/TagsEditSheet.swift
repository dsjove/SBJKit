import SwiftUI
import SwiftData

public struct TagsEditSheet<T: Taggable, B: TagBag> : View where T.Tag == B.Tag {
	typealias Tag = T.Tag

	@Environment(\.dismiss) private var dismiss

	@Bindable public var tagBag: B
	public let taggable: T?

	@State private var searchText = ""
	@State private var editColorTag: Tag?
	@FocusState private var isTagFieldFocused: Tag.ID?
	@State private var lastAddedTagID: Tag.ID?

	public init(tagBag: B, taggable: T?) {
		self.tagBag = tagBag
		self.taggable = taggable
	}

	public var body: some View {
		NavigationStack {
			VStack {
				let sortedTags = tagBag.tags(searchText)
				SearchField("Search Tags", searching: $searchText)
					.padding(.horizontal)
				ScrollViewReader { proxy in
					List {
						if sortedTags.isEmpty {
							AddButton("Tag", labeled: true, add: addTag)
								.buttonStyle(.borderedProminent)
						} else {
							ForEach(sortedTags) { tag in
								HStack {
									Rectangle()
										.fill(tag.color.swiftUIColor)
										.frame(width: 44, height: 44)
										.cornerRadius(8.0)
										.onTapGesture {
											//editColorTag = tag
										}
									TextField("Name", text: Binding(
										get: { tag.name },
										set: { tag.name = $0 }
									))
									.focused($isTagFieldFocused, equals: tag.id)
									.submitLabel(.done)
									.onSubmit {
										isTagFieldFocused = nil
									}
									.autocapitalization(.none)
									.disableAutocorrection(true)
									.overlay(
										RoundedRectangle(cornerRadius: 6)
											.stroke(Color.accentColor, lineWidth: isTagFieldFocused == tag.id ? 2 : 0)
									)
									.shadow(color: isTagFieldFocused == tag.id ? Color.accentColor.opacity(0.25) : .clear, radius: isTagFieldFocused == tag.id ? 5 : 0)
									if let taggable {
										Toggle(isOn: Binding(
											get: { taggable.hasTag(tag) },
											set: { newValue in
												if newValue {
													taggable.addTag(tag)
												} else {
													taggable.removeTag(tag)
												}
											}
										)) {}
										.toggleStyle(.checkbox)
										Button {
											taggable.addTag(tag, makePrimary: true)
										} label: {
											Image(systemName: taggable.primaryTag?.id == tag.id ? "star.fill" : "star")
										}
										.buttonStyle(.plain)
									}
								}
								.background(
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.fill(taggable?.primaryTag?.id == tag.id ? Color.secondary.opacity(0.13) : Color.clear)
										.padding(-8)
								)
								.tag(tag.id)
							}
							.onDelete { offsets in
								let toBeDeleted = offsets.map { sortedTags[$0] }
								withAnimation {
									tagBag.deleteTags(toBeDeleted)
								}
							}
						}
					}
					.onChange(of: lastAddedTagID) { _, id in
						if let id {
							withAnimation {
								proxy.scrollTo(id, anchor: .center)
							}
							lastAddedTagID = nil
						}
					}
				}
			}
			.navigationBarTitle("Tags", displayMode: .inline)
			.toolbar {
				ToolbarItemGroup(placement: .topBarLeading) {
					DismissButton {
						tagBag.dismissed()
						dismiss()
					}
				}
				ToolbarItemGroup(placement: .topBarTrailing) {
					AddButton("Tag", add: addTag)
					HelpButton(asset: .init(title: "Edit Tags", folder: "help", mainBundle: false))
				}
			}
			.sheet(item: $editColorTag) { tag in
				ColorPickerView(title: tag.name, selectedColor: Binding(
					get: { tag.color.swiftUIColor },
					set: { tag.color.swiftUIColor = $0 }
				))
				.presentationDetents([.medium])
			}
		}
		.presentationDetents([.large])
	}

	func addTag() {
		let newTag = tagBag.addNewTag(named: searchText)
		taggable?.addTag(newTag)
		searchText = ""
		isTagFieldFocused = newTag.id
		lastAddedTagID = newTag.id
	}
}
