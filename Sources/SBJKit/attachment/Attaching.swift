import SwiftData
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import SBJKit

public protocol Attaching:
	AnyObject,
	Identifiable,
	TearDownable,
	Predicated,
	CustomDebugStringConvertible,
	Comparable where ID: Comparable {

	var name: String { get set }
	var bookmark: Data { get set }
	var displayName: String { get }

	init(name: String, bookmark: Data)
}

public extension Attaching {
	var displayName: String { name }

	init(url: URL) throws {
		// iOS requires **NO security scope options**
		let bookmark = try url.bookmarkData(
			options: [],
			includingResourceValuesForKeys: nil,
			relativeTo: nil
		)
		self.init(name: url.lastPathComponent, bookmark: bookmark)
	}

	func url() throws -> URL {
		var isStale = false
		let url = try URL(
			resolvingBookmarkData: bookmark,
			options: [],
			relativeTo: nil,
			bookmarkDataIsStale: &isStale
		)
		if isStale {
			if let newData = try? url.bookmarkData(
				options: [],
				includingResourceValuesForKeys: nil,
				relativeTo: nil
			) {
				bookmark = newData
			}
		}
		return url
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		let nameCompare = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
		if nameCompare != .orderedSame {
			return nameCompare == .orderedAscending
		}
		return lhs.id < rhs.id
	}

	func predicated(search: String) -> Bool {
		guard let query = search.querify else { return true }
		return name.predicated(search: query)
	}

	var debugDescription: String {
		"\(Self.self): \(name)"
	}
}

public protocol AttachmentOwner: AnyObject {
	associatedtype Attachment: Attaching
	var __attachments: [Attachment]? { get set }
	func __createAttachment(_ url: URL) throws -> Attachment
}

public extension AttachmentOwner {
	var AttachmentCount: Int {
		__attachments?.count ?? 0
	}

	func hasAttachment(_ attachment: Attachment) -> Bool {
		__attachments?.containsIdentified(attachment) ?? false
	}

	@discardableResult
	func addAttachment(url: URL) throws -> Attachment {
		if __attachments == nil {
			__attachments = []
		}
		let attachment = try __createAttachment(url)
		__attachments?.addIdentified(attachment)
		return attachment
	}

	var sortedAttachments: [Attachment] {
		__attachments?.sorted() ?? []
	}

	func removeAttachment(_ attachment: Attachment) {
		__attachments?.removeIdentified(attachment)
		attachment.tearDown()
	}
}
