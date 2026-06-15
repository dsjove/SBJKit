import Foundation
import SwiftData

extension Schema.Version: DefaultsStorageValue {
	public init?(from description: String?) {
		guard let description, !description.isEmpty else { return nil }
		let parts = description.split(separator: ".", omittingEmptySubsequences: false)
		if parts.count >= 1 {
			guard let major = Int(parts[0]) else { return nil }
			if parts.count >= 2 {
				guard let minor = Int(parts[1]) else { return nil }
				if parts.count >= 3 {
					guard let patch = Int(parts[2]) else { return nil }
					self.init(major, minor, patch)
				}
				else {
					self.init(major, minor, 0)
				}
			}
			else {
				self.init(major, 0, 0)
			}
		}
		return nil
	}

	public static func read(from defaults: UserDefaults, key: String) -> Schema.Version? {
		let str = defaults.string(forKey: key)
		return .init(from: str)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self.description, forKey: key)
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
			try modelContext?.save()
		}
		catch {
			//TODO: log full NSError
		}
	}
}
