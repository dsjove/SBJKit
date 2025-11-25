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
	private var didLoadTags = false
	
	@Published public private(set) var tags: [Tag] = []

	public var title: String { factory.title }

	public init(modelContext: ModelContext, factory: Factory) {
		self.modelContext = modelContext
		self.factory = factory
	}

	private func loadTagsIfNeeded() {
		guard !didLoadTags else { return }
		do {
			factory.seedTags()
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
