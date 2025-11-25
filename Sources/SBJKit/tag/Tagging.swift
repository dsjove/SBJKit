import Foundation
import SwiftUI
import SwiftData

public protocol Tagging:
	AnyObject,
	Observable,
	Identifiable,
	Predicated,
	CustomDebugStringConvertible,
	Comparable where ID: Comparable {
	
	var name: String { get set }
	var color: CodableColor { get set }

	var displayName: String { get }

	func fullDelete()
}

public extension Tagging where Self: PersistentModel {
	func fullDelete() {
		self.deleteNow()
	}
}

public extension Tagging {
	var displayName: String {
		name
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.name.localizedCaseInsensitiveCompare(rhs.name) != .orderedSame {
			return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
		}
		if lhs.color != rhs.color {
			return lhs.color < rhs.color
		}
		return lhs.id < rhs.id
	}

	func predicated(search: String) -> Bool {
		guard let query = search.querify else { return true }
		return name.predicated(search: query)
	}

	var debugDescription: String {
		"\(Self.self): \(name)\(self.color.debugDescription)"
	}
	
	func fullDelete() {
	}
}

public extension Tagging {
	var foregroundColor: Color {
		UIColor(self.color.swiftUIColor).isLight ? .black : .white
	}

	var backgroundColor: Color {
		self.color.swiftUIColor
	}

	@ViewBuilder
	func label(isPrimary: Bool = false) -> some View {
		Text(displayName)
			.font(.caption).bold()
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(backgroundColor)
			.foregroundColor(foregroundColor)
			.cornerRadius(8)
			.overlay(
				RoundedRectangle(cornerRadius: 8)
					.stroke(isPrimary ? Color.black : Color.clear, lineWidth: 2)
			)
	}
}

public protocol Taggable: AnyObject {
	associatedtype Tag: Tagging
	
	func hasTag(_ tag: Tag) -> Bool
	var sortedTags: [Tag] { get }
	func addTag(_ tag: Tag, makePrimary: Bool)
	func removeTag(_ tag: Tag)

	var tags: [Tag]! { get set }
	var primaryTag: Tag? { get set }
}

public extension Taggable {
	func hasTag(_ tag: Tag) -> Bool {
		tags.containsIdentified(tag)
	}

	func addTag(_ tag: Tag) {
		addTag(tag, makePrimary: false)
	}

	var sortedTags: [Tag] {
		return tags.sorted()
	}

	func addTag(_ tag: Tag, makePrimary: Bool = false) {
		tags.addIdentified(tag)
		if makePrimary || primaryTag == nil {
			primaryTag = tag
		}
	}

	func removeTag(_ tag: Tag) {
		tags.removeIdentified(tag)
	}
}

public protocol TagBag: AnyObject, Observable {
	associatedtype Tag: Tagging
	var title: String { get }
	func tags(_ search: String) -> [Tag]
	func addNewTag(named name: String) -> Tag
	func deleteTags(_ toBeDeleted: [Tag])
}

public extension TagBag {
	func addNewTag() -> Tag {
		addNewTag(named: "")
	}
}

public protocol TagBagFactory {
	associatedtype Tag: Tagging
	var title: String { get }
	func seedTags()
	func createTag(named: String) -> Tag
}

public extension TagBagFactory {
	var title: String { "Tags" }
	func seedTags() {}
}
