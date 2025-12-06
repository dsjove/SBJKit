import SwiftData
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import SBJKit

public struct AttachmentsView<Owner: AttachmentOwner & Observable>: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL

	@Bindable var owner: Owner

	@State private var previewURL: IdentifiedURL?
	@State private var isImporterPresented = false
	@State private var importerError: String?

	private var attachments: [Owner.Attachment] {
		owner.sortedAttachments
	}

	public init(owner: Owner) {
		self.owner = owner
	}

	public var body: some View {
		NavigationStack {
			List {
				ForEach(attachments) { attachment in
					HStack {
						TextField("Name", text: Binding(
							get: { attachment.name },
							set: { attachment.name = $0 }
						))
						.oneLiner()
						Spacer()
						Button {
							openAttachment(attachment)
						} label: {
							Image(systemName: "chevron.right")
								.font(.body.weight(.semibold))
						}
						.buttonStyle(.plain)
					}
				}
				.onDelete(perform: deleteAttachments)
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle("Attachments")
			.toolbar {
				ToolbarItemGroup(placement: .topBarLeading) {
					DismissButton() {
						dismiss()
					}
				}
				ToolbarItemGroup(placement: .topBarTrailing) {
					AddButton("Attachment") {
						isImporterPresented = true
					}
				}
			}
			.fileImporter(
				isPresented: $isImporterPresented,
				allowedContentTypes: [.item],
				allowsMultipleSelection: true
			) { result in
				handleImportResult(result)
			}
			.alert("Error", isPresented: .constant(importerError != nil)) {
				Button("OK") { importerError = nil }
			} message: {
				Text(importerError ?? "")
			}
			.fullScreenCover(item: $previewURL) { item in
				DocumentPreviewSheet(url: item.value, title: item.value.lastPathComponent)
			}
		}
	}

	// MARK: - Import

	private func handleImportResult(_ result: Result<[URL], Error>) {
		switch result {
		case .success(let urls):
			for url in urls {
				let accessing = url.startAccessingSecurityScopedResource()
				defer {
					if accessing {
						url.stopAccessingSecurityScopedResource()
					}
				}
				// Optional: sanity check – useful while debugging
				if !FileManager.default.fileExists(atPath: url.path) {
					print("DEBUG: File does not exist at path: \(url.path)")
				}
				do {
					let _ = try owner.addAttachment(url: url)
				} catch {
					importerError = error.localizedDescription
					print("DEBUG: bookmarkData error:", error)
				}
			}
		case .failure(let error):
			importerError = error.localizedDescription
			print("DEBUG: fileImporter error:", error)
		}
	}

	// MARK: - Open Attachment

	private func openAttachment(_ attachment: Owner.Attachment) {
		do {
			let url = try attachment.url()
			previewURL = IdentifiedURL(url)
		} catch {
			importerError = error.localizedDescription
		}
	}

	private func openInternal(url: URL) {
		let accessing = url.startAccessingSecurityScopedResource()
		defer {
			if accessing {
				url.stopAccessingSecurityScopedResource()
			}
		}
		openURL(url) { success in
			print("openURL success:", success)
		}
	}

	// MARK: - Delete

	private func deleteAttachments(at offsets: IndexSet) {
		offsets.forEach { index in
			owner.removeAttachment(attachments[index])
		}
	}
}
