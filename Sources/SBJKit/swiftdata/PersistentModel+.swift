import Foundation
import SwiftData

public extension Error {
	func printAsNSError() {
		let nsError = self as NSError
		print("• error: \(self)")
		print("• code: \(nsError.code)")
		print("• domain: \(nsError.domain)")
		print("• userInfo: \(nsError.userInfo)")
		print("• description: \(nsError.localizedDescription)")
		print("• reason: \(nsError.localizedFailureReason ?? "")")
		print("• options: \(nsError.localizedRecoveryOptions ?? [])")
		print("• suggestion: \(nsError.localizedRecoverySuggestion ?? "")")
	}
}

public extension PersistentIdentifier {
	var base64String: String? {
		let encoder = JSONEncoder()
		guard let data = try? encoder.encode(self) else { return nil }
		return data.base64EncodedString()
	}

	init?(base64String: String) {
		guard let data = Data(base64Encoded: base64String)
			else { return nil }
		guard let identifier = try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
			else { return nil }
		self = identifier
	}
	
	func find<T: PersistentModel>(_ modelContext: ModelContext?) -> T? {
		modelContext?.model(for: self) as? T
	}
}

public extension PersistentModel {
	func deleteNow() {
		guard let mc = modelContext, !isDeleted else { return }
		mc.delete(self)
		saveNow()
	}

	@discardableResult
	func insertNow(_ modelContext: ModelContext?, populate: (Self) -> Void = { _ in }) -> Self {
		//TODO: what if existing context is same or different?
		modelContext?.insert(self)
		populate(self)
		saveNow()
		//Is this necessary?
		//let canonical = try context.fetch(FetchDescriptor<AssemblySet>(predicate: #Predicate { $0 == newSet })).first
		//return canonical
		return self
	}

	func saveNow() {
		do {
			try try modelContext?.save()
		}
		catch {
			//TODO: log full NSError
		}
	}
}

public extension Array where Element: Identifiable {
	func containsIdentified(_ model: Element) -> Bool {
		contains { $0.id == model.id }
	}

	func identifiedIndex(_ model: Element) -> Index? {
		firstIndex { $0.id == model.id }
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
