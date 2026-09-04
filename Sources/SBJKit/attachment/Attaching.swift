import Foundation
import SwiftUI
import UniformTypeIdentifiers
import SBJFoundation

public protocol Attaching:
	AnyObject,
	Identifiable,
	TearDownable,
	Predicated,
	CustomDebugStringConvertible,
	Comparable where ID: Comparable {

	var timestamp: Date { get }
	var name: String { get set }
	var bookmark: Data { get set }
	var displayName: String { get }

	init(name: String, bookmark: Data)
}

public extension Attaching {
	var displayName: String { name }

	init(url: URL) throws {
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
		if lhs.timestamp != rhs.timestamp {
			return lhs.timestamp < rhs.timestamp
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
	var attachmentCount: Int {
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
