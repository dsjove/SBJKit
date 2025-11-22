import SwiftData

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
