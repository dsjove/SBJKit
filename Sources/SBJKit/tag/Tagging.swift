import Foundation
import SwiftUI

public protocol Tagging:
	AnyObject,
	Observable,
	Identifiable,
	CustomDebugStringConvertible,
	Comparable where ID: Comparable {
	
	var name: String { get set }
	var color: CodableColor { get set }

	var displayName: String { get }
	func predicated(_ search: String) -> Bool
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

	func predicated(_ search: String) -> Bool {
		if search.isEmpty {
			return true
		}
		return name.lowercased().contains(search.lowercased())
	}

	var debugDescription: String {
		"\(Self.self): \(name)\(self.color.debugDescription)"
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

public protocol Taggable {
	associatedtype Tag: Tagging
	func hasTag(_ tag: Tag) -> Bool
	var selectedTags: [Tag] { get }
	func addTag(_ tag: Tag, makePrimary: Bool)
	func removeTag(_ tag: Tag)
	var primaryTag: Tag? { get }
}

public extension Taggable {
	func hasTag(_ tag: Tag) -> Bool {
		selectedTags.contains(where: { $0 === tag })
	}

	func addTag(_ tag: Tag) {
		addTag(tag, makePrimary: false)
	}
}

public protocol TagBag: AnyObject, Observable {
	associatedtype Tag: Tagging
	func tags(_ search: String) -> [Tag]
	func addNewTag(named name: String) -> Tag
	func deleteTags(_ toBeDeleted: [Tag])
	func dismissed()
}

public extension TagBag {
	func addNewTag() -> Tag {
		addNewTag(named: "")
	}
}

public protocol TagBagDelegate {
	associatedtype Tag: Tagging
	func seedTags()
	func createTag(named: String) -> Tag
	func willDelete(tag: Tag)
}

extension TagBagDelegate {
	func seedTags() {}
	func willDelete(tag: Tag) {}
}
