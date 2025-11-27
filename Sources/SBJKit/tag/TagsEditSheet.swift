import SwiftUI
import SwiftData

public struct TagsEditSheet<T: TagUser, B: TagBag> : View where T.Tag == B.Tag {
	typealias Tag = T.Tag

	@Environment(\.dismiss) private var dismiss

	@Bindable var tagBag: B
	let user: T?

	@State private var searchText = ""
	@State private var editColorTag: Tag?
	@FocusState private var isTagFieldFocused: Tag.ID?
	@State private var lastAddedTagID: Tag.ID?
	@State private var pendingDeletion: [Tag] = []
	@State private var showDeleteConfirmation = false

	public init(tagBag: B, user: T?) {
		self.tagBag = tagBag
		self.user = user
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
											editColorTag = tag
										}
									VStack(alignment: .leading, spacing: 2) {
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

										if tag.userCount > 0 {
											Text("(\(tag.userCount))")
												.font(.caption)
												.foregroundStyle(.secondary)
										}
									}
									if let user {
										Toggle(isOn: Binding(
											get: { user.hasTag(tag) },
											set: { newValue in
												if newValue {
													user.addTag(tag)
												} else {
													user.removeTag(tag)
												}
											}
										)) {}
										.toggleStyle(.checkbox)
										Button {
											user.addTag(tag, makePrimary: true)
										} label: {
											Image(systemName: user.isTagPrimary(tag) ? "star.fill" : "star")
										}
										.buttonStyle(.plain)
									}
								}
								.background(
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.fill((user?.isTagPrimary(tag) ?? false) ? Color.secondary.opacity(0.13) : Color.clear)
										.padding(-8)
								)
							}
							.onDelete { offsets in
								let toBeDeleted = offsets.map { sortedTags[$0] }
								let shouldPrompt = toBeDeleted.allSatisfy { !$0.isSoleUser(user) }
								if shouldPrompt {
									pendingDeletion = toBeDeleted
									showDeleteConfirmation = true
								} else {
									withAnimation {
										tagBag.deleteTags(toBeDeleted)
									}
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
			.navigationBarTitle(tagBag.title, displayMode: .inline)
			.toolbar {
				ToolbarItemGroup(placement: .topBarLeading) {
					DismissButton {
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
			.alert(
				Text("Delete Tag" + (pendingDeletion.count > 1 ? "s" : "")),
				isPresented: $showDeleteConfirmation
			) {
				Button("Cancel", role: .cancel) {
					pendingDeletion.removeAll()
				}
				Button("Delete", role: .destructive) {
					withAnimation {
						tagBag.deleteTags(pendingDeletion)
						pendingDeletion.removeAll()
					}
				}
			} message: {
				if pendingDeletion.count == 1, let name = pendingDeletion.first?.name {
					Text("Are you sure you want to delete \"\(name)\"?")
				} else {
					Text("Are you sure you want to delete \(pendingDeletion.count) tags?")
				}
			}
		}
		.presentationDetents([.large])
	}

	func addTag() {
		let newTag = tagBag.addNewTag(named: searchText)
		user?.addTag(newTag)
		searchText = ""
		isTagFieldFocused = newTag.id
		lastAddedTagID = newTag.id
	}
}

