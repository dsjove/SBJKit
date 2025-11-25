import SwiftData
import Foundation

public protocol SearchProtocol {
	var text: String { get set }
	var isEmpty: Bool { get }
}

public protocol Predicated {
	func predicated(search: String) -> Bool
}

extension String: Predicated {
	public var querify: String? {
		let query = self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		return query.isEmpty ? nil : query
	}

	public func predicated(search: String) -> Bool {
		guard let query = search.querify else { return true }
		return self.querify?.contains(query) == true
	}
}

public extension Array where Element: Predicated {
	func predicated(search: String) -> Bool {
		contains(where: { $0.predicated(search: search) })
	}
	func filter(search: String) -> [Element] {
		filter({ $0.predicated(search: search) })
	}
}

extension String: SearchProtocol {
	public var text: String {
		get { self }
		set { self = newValue }
	}
}
