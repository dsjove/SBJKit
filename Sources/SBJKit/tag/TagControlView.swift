import SwiftUI

public struct TagsControlView<T: Taggable>: View {
	private let taggable: T
	private let showTagsSheet: (()->())?

	public init(taggable: T, showTagsSheet: (() -> Void)?) {
		self.taggable = taggable
		self.showTagsSheet = showTagsSheet
	}

	public var body: some View {
		HStack {
			if let showTagsSheet {
				ActionButton("Edit Tags", image: "tag.fill") {
					showTagsSheet()
				}
				.buttonStyle(.borderedProminent)
			}
			let sortedTags = taggable.selectedTags
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 10) {
					if sortedTags.isEmpty {
						Text("No Tags")
							.font(.body)
							.italic(true)
							.padding(.trailing)
							.onTapGesture(count: 1) {
								if let showTagsSheet {
									showTagsSheet()
								}
							}
					} else {
						ForEach(sortedTags) { item in
							item.label(isPrimary: item.id == taggable.primaryTag?.id)
						}
					}
				}
				.padding()
			}
		}
	}
}
