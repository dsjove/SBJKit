import SwiftData

public extension PersistentModel {
	func deleteNow() {
		let mc = self.modelContext
		mc?.delete(self)
		do {
			try mc?.save()
		}
		catch {
			//assertionFailure("Save failed: \(error)")
		}
	}

	@discardableResult
	func insertNow(_ modelContext: ModelContext, populate: (Self) -> Void = { _ in }) -> Self {
		modelContext.insert(self)
		populate(self)
		do {
			try modelContext.save()
		}
		catch {
			//assertionFailure("Save failed: \(error)")
		}
		//let canonical = try context.fetch(FetchDescriptor<AssemblySet>(predicate: #Predicate { $0 == newSet })).first
		return self
	}
}

public extension Array where Element: PersistentModel {
	func containsModel(_ model: Element) -> Bool {
		contains { $0.id == model.id }
	}

	@discardableResult
	mutating func addModel(_ model: Element) -> Bool {
		guard !containsModel(model) else { return false }
		append(model)
		return true
	}

	@discardableResult
	mutating func removeModel(_ model: Element) -> Bool {
		if let index = firstIndex(where: { $0.id == model.id }){
			remove(at: index)
			return true
		}
		return false
	}
}
