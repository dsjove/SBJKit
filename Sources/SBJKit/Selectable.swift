import Foundation
import SwiftData

public protocol Selectable {
	var selectionID: UUID { get }
}

public extension Array where Element: Selectable {
	func uniqueIndex(_ model: Element?) -> Index? {
		firstIndex { $0.selectionID == model?.selectionID }
	}

	func findUnique(_ id: UUID?) -> Element? {
		guard let id else { return nil }
		return first { $0.selectionID == id }
	}

	func containsUnique(_ model: Element?) -> Bool {
		guard let model else { return false }
		return contains { $0.selectionID == model.selectionID }
	}

	@discardableResult
	mutating func addUnique(_ model: Element) -> Bool {
		guard !containsUnique(model) else { return false }
		append(model)
		return true
	}

	@discardableResult
	mutating func removeUnique(_ model: Element) -> Bool {
		guard let index = uniqueIndex(model) else { return false }
		remove(at: index)
		return true
	}
}

public extension ModelContext {
	func find<T: Selectable & PersistentModel>(selection id: UUID?) -> T? {
		guard let id else { return nil }
		var fetching = FetchDescriptor<T>(
			predicate: #Predicate { $0.selectionID == id }
		)
		fetching.fetchLimit = 1
		return try? fetch(fetching).first!
	}
}

//TODO: use a key path to a thing that is equatable
public extension Array where Element: Identifiable {
	func nextIdentified(_ model: Element) -> Element? {
		if let idx = self.identifiedIndex(model) {
			if self.count == 1 {
				return nil
			}
			else if idx < self.count - 1 {
				return self[idx+1]
			}
			return self[idx-1]
		}
		return self.last
	}

	func hasOtherIdentified(_ model: Element?) -> Bool {
		guard !self.isEmpty else { return false }
		guard !self.containsIdentified(model) else { return true }
		guard self.count > 1 else { return false }
		return true
	}

	func findIdentified(_ id: Element.ID?) -> Element? {
		guard let id else { return nil }
		return first { $0.id == id }
	}

	func containsIdentified(_ model: Element?) -> Bool {
		guard let model else { return false }
		return contains { $0.id == model.id }
	}

	func identifiedIndex(_ model: Element?) -> Index? {
		firstIndex { $0.id == model?.id }
	}

	@discardableResult
	mutating func addIdentified(_ model: Element) -> Bool {
		guard !containsIdentified(model) else { return false }
		append(model)
		return true
	}

	@discardableResult
	mutating func removeIdentified(_ model: Element) -> Bool {
		guard let index = identifiedIndex(model) else { return false }
		remove(at: index)
		return true
	}
}
