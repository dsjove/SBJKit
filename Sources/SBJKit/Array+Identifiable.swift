import Foundation
import SwiftData

public extension ModelContext {
	func find<T: PersistentModel>(selection id: T.ID?) -> T? {
		guard let id else { return nil }
		var descriptor = FetchDescriptor<T>()
		if let results = try? self.fetch(descriptor) {
			return results.first { $0.id == id }
		}
		return nil
	}
//	func find1<T: PersistentModel>(selection id: T.ID?) -> T? {
//		guard let id else { return nil }
//        let predicate = Predicate<T> { variable in
//            PredicateExpressions.Equal(
//				lhs: PredicateExpressions.KeyPath(root: variable, keyPath: \T.id),
//				rhs: PredicateExpressions.Value(id)
//            )
//        }
//        var descriptor = FetchDescriptor<T>(predicate: predicate)
//        descriptor.fetchLimit = 1
//
//        return try? fetch(descriptor).first
//	}
//	func find2<T: PersistentModel>(selection id: T.ID?) -> T? {
//		guard let id else { return nil }
//		var descriptor = FetchDescriptor<T>(predicate: #Predicate {
//			$0.id == id
//		})
//		descriptor.fetchLimit = 1
//		if let results = try? self.fetch(descriptor) {
//			return results.first
//		}
//		return nil
//	}
//	func find3<T: PersistentModel, K: Comparable>(selection id: K?, from: KeyPath<T, K>) -> T? {
//		guard let id else { return nil }
//		var descriptor = FetchDescriptor<T>(predicate: #Predicate {
//			$0[keyPath: from] == id
//		})
//		descriptor.fetchLimit = 1
//		if let results = try? self.fetch(descriptor) {
//			return results.first
//		}
//		return nil
//	}
}

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
