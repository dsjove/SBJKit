import SwiftUI
import SwiftData
import Foundation

@MainActor
public final class TagBagSwiftData<F>: ObservableObject, @MainActor TagBag
where F: TagBagFactory, F.Tag: PersistentModel {
	public typealias Tag = F.Tag
	public typealias Factory = F

	private let modelContext: ModelContext
	private let factory: Factory
	
	@Published public private(set) var tags: [Tag] = []

	public var title: String { factory.title }

	public init(modelContext: ModelContext, factory: Factory) {
		self.modelContext = modelContext
		self.factory = factory
	}

	private func loadTagsIfNeeded() {
		guard tags.isEmpty else { return }
		do {
			//factory.seedTags()
			let fetched = try modelContext.fetch(FetchDescriptor<Tag>())
			self.tags = fetched
		} catch {
		}
	}

	public func tags(_ search: String) -> [Tag] {
		loadTagsIfNeeded()
		return tags.filter(search: search)
	}

	public func addNewTag(named name: String) -> Tag {
		loadTagsIfNeeded()
		if let existing = tags.first(where: {$0.name == name}) {
			return existing
		}
		let newTag = factory.createTag(named: name)
		tags.addIdentified(newTag)
		newTag.insertNow(modelContext)
		return newTag
	}

	public func deleteTags(_ toBeDeleted: [Tag]) {
		loadTagsIfNeeded()
		for tag in toBeDeleted {
			tags.removeIdentified(tag)
			DispatchQueue.main.async {
				tag.fullDelete()
			}
		}
	}
}
