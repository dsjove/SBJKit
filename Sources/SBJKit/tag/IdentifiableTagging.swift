import Foundation
import SwiftUI

public protocol IdentifiableTagging: Tagging, Identifiable, AnyObject {
	associatedtype User: IdentifiableTaggable where User.Tag == Self
	var taggable : [User]! { get set }
	var asPrimary : [User]! { get set }

	func taggableRemoved(_ taggable: User)
}

public protocol IdentifiableTaggable: Taggable, Identifiable, AnyObject where Tag: IdentifiableTagging, Tag.User == Self {
	var tags : [Tag] { get set }
	var primaryTag: Tag? { get set }
}

public extension IdentifiableTagging {
	func taggableRemoved(_ taggable: User) {
		self.taggable.removeIdentified(taggable)
		self.asPrimary.removeIdentified(taggable)
	}

	func fullDelete() {
		taggable.forEach { $0.removeTag(self) }
	}
}

public extension IdentifiableTaggable {
	var sortedTags: [Tag] {
		return tags.sorted()
	}

	func hasTag(_ tag: Tag) -> Bool {
		tags.containsIdentified(tag)
	}

	func addTag(_ tag: Tag, makePrimary: Bool = false) {
		tags.addIdentified(tag)
		if makePrimary || primaryTag == nil {
			primaryTag = tag
		}
	}

	func removeTag(_ tag: Tag) {
		tags.removeIdentified(tag)
		if primaryTag?.id == tag.id {
			primaryTag = sortedTags.first { $0.id != tag.id }
		}
		tag.taggableRemoved(self)
	}
}
