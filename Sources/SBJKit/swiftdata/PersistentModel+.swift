import Foundation
import SwiftData

extension Schema.Version: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Schema.Version? {
		let str = defaults.string(forKey: key)
		let parts = str?.split(separator: ".", omittingEmptySubsequences: false) ?? []
		guard parts.count == 3,
		      let major = Int(parts[0]),
		      let minor = Int(parts[1]),
		      let patch = Int(parts[2]) else {
			return nil
		}
		return .init(major, minor, patch)
	}
	
	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self.description, forKey: key)
	}
}

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
	func deleteNow(save: Bool = true) {
		guard let mc = modelContext, !isDeleted else { return }
		mc.delete(self)
		if save {
			saveNow()
		}
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
