import Foundation
import SwiftUI
import UniformTypeIdentifiers

public protocol DataAttachment {
	var blob: Data { get }
	var utiType: String { get }
	var filename: String { get }
	var fileExt: String { get }
}

public extension DataAttachment {
	var filename: String {
		""
	}

	var fileExt: String {
		if let utType, let ext = utType.preferredFilenameExtension {
			return ext
		}
		return filename.split(separator: ".").last.map(String.init) ?? ""
	}

	var utType: UTType? {
		UTType(utiType)
	}

	func previewFilename() -> String {
		let original = URL(fileURLWithPath: filename).lastPathComponent
		if !URL(fileURLWithPath: original).pathExtension.isEmpty {
			return original
		}
		if !fileExt.isEmpty {
			return original + "." + fileExt
		}
		return original
	}

	func previewURL(app: String) throws -> URL {
		let previewDirectory = try Self.makePreviewDirectory(app: app)
		let previewFileURL = previewDirectory.appendingPathComponent(previewFilename())
		return previewFileURL
	}

	@MainActor
	public static func item(content: String, name: String? = nil, ext: String? = nil) -> Any {
		if let name {
			let suffix = ext.map { $0.isEmpty ? "" : ".\($0)" } ?? ""
			let fileName = name.sanitizedFilename() + suffix
			if let fileURL = URL.writeToTempFile(named: fileName, content: content) {
				return fileURL
			}
		}
		return content
	}

	static func makePreviewDirectory(app: String) throws -> URL {
		let directory = FileManager.default.temporaryDirectory
			.appendingPathComponent(app, isDirectory: true)
			.appendingPathComponent(UUID().uuidString, isDirectory: true)

		try FileManager.default.createDirectory(
			at: directory,
			withIntermediateDirectories: true
		)
		return directory
	}
}

public extension DataAttachment where Self: ItemProviding {
	/// Builds an NSItemProvider that defers loading until requested by the share sheet target.
	/// Requires conformers to provide `blob` (Data), `utiType` (String), and `filename` (String).
	/// Optionally, if a `thumbnailImage` property exists via another protocol conformance,
	/// it will be used to provide a preview representation.
	func makeItemProvider() -> NSItemProvider {
		let provider = NSItemProvider()
		provider.registerDataRepresentation(forTypeIdentifier: utiType, visibility: .all) { completion in
			completion(self.blob, nil)
			return nil
		}
		provider.suggestedName = filename

		// If the conformer exposes a thumbnail image via casting, register it for preview.
		if let thumbSource = self as? ThumbnailProviding, let image = thumbSource.thumbnailImage() {
			provider.registerItem(forTypeIdentifier: "public.png", loadHandler: { completion, _, _ in
				if let png = image.pngData() {
					completion?(png as NSSecureCoding, nil)
				} else {
					completion?(nil, NSError(domain: "ShareSheet.DataAttachment", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail data"]))
				}
			})
		}
		return provider
	}
}

public protocol ItemProviding {
	func makeItemProvider() -> NSItemProvider
}

public protocol ThumbnailProviding {
	func thumbnailImage() -> UIImage?
}

public struct CapturedAttachment: DataAttachment {
	public let blob: Data
	public let utiType: String

	public init(blob: Data, utiType: String) {
		self.blob = blob
		self.utiType = utiType
	}
}

public protocol PhotoImport {
	var blob: Data { get }
	var filename: String { get }
}
