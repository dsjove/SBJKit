import SwiftUI

public struct TagsListView<T: Taggable>: View {
	private let taggable: T

	public init(taggable: T) {
		self.taggable = taggable
	}

	public var body: some View {
		let sortedTags = taggable.selectedTags
		HStack(spacing: 10) {
			if sortedTags.isEmpty {
				Text("No Tags")
					.font(.body)
					.italic(true)
					.padding(.trailing)
			} else {
				ForEach(sortedTags) { item in
					item.label(isPrimary: item.id == taggable.primaryTag?.id)
				}
			}
		}
	}
}
