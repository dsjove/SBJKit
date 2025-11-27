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
