import SwiftUI
import SwiftData
import Foundation

@MainActor
public final class TagBagSwiftData<D>: ObservableObject, @MainActor TagBag
		where D: TagBagDelegate, D.Tag: PersistentModel {
	public typealias Tag = D.Tag
	public typealias Delegate = D
	private let modelContext: ModelContext
	private let delegate: D
	private var didLoadTags = false
	
	@Published public private(set) var tags: [Tag] = []

	public init(modelContext: ModelContext, delegate: Delegate) {
		self.modelContext = modelContext
		self.delegate = delegate
	}

	private func loadTagsIfNeeded() {
		guard !didLoadTags else { return }
		do {
			delegate.seedTags()
			let tags = try modelContext.fetch(FetchDescriptor<Tag>())
			self.didLoadTags = tags.isEmpty == false
			if self.didLoadTags {
				DispatchQueue.main.async {
					self.tags = tags
				}
			}
		} catch {
		}
	}

	public func tags(_ search: String) -> [Tag] {
		loadTagsIfNeeded()
		if search.isEmpty {
			return tags.sorted().filter { !$0.isDeleted }
		}
		let lc = search.lowercased()
		return tags.filter { $0.predicated(lc) }.sorted().filter { !$0.isDeleted }
	}

	public func addNewTag(named name: String) -> Tag {
		loadTagsIfNeeded()
		if let existing = tags.first(where: {$0.name == name}) {
			return existing
		}
		let newTag = delegate.createTag(named: name)
		tags.addModel(newTag)

		modelContext.insert(newTag)
		performSave()
		return newTag
	}

	public func deleteTags(_ toBeDeleted: [Tag]) {
		loadTagsIfNeeded()
		for tag in toBeDeleted {
			delegate.willDelete(tag: tag)
			tags.removeModel(tag)
			DispatchQueue.main.async {
				self.modelContext.delete(tag)
				self.performSave()
			}
		}
	}

	public func dismissed() {
		self.performSave()
	}

	private func performSave() {
		do {
			try modelContext.save()
		} catch {
		}
	}
}
