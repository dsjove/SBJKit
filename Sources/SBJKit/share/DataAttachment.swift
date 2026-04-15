import Foundation
import SwiftUI
import UniformTypeIdentifiers

public protocol DataAttachment {
	var blob: Data { get }
	var utiType: String { get }
	var name: String { get }
}

//NOTE: share sheets really want to work with URLs

public extension DataAttachment {
	var sanitizedName: String {
		name.sanitizedFilename()
	}

	var fileExt: String {
		if let utType, let ext = utType.preferredFilenameExtension {
			return ext
		}
		return name.split(separator: ".").last.map(String.init) ?? ""
	}

	var utType: UTType? {
		UTType(utiType.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
	}

	var filename: String {
		let original = sanitizedName
		if !URL(fileURLWithPath: original).pathExtension.isEmpty {
			return original
		}
		if !fileExt.isEmpty {
			return original + "." + fileExt
		}
		return original
	}

	func shareURL(subDir: String) throws -> URL {
		let shareDirectory = try Self.makeShareDirectory(subDir: subDir)
		let shareURL = shareDirectory.appendingPathComponent(filename)
		try blob.write(to: shareURL, options: .atomic)
		return shareURL
	}

	static func makeShareDirectory(subDir: String) throws -> URL {
		let directory = FileManager.default.temporaryDirectory
			.appendingPathComponent(subDir, isDirectory: true)
			.appendingPathComponent(UUID().uuidString, isDirectory: true)

		try FileManager.default.createDirectory(
			at: directory,
			withIntermediateDirectories: true
		)
		return directory
	}
}

public func isPlausibleTypeIdentifier(_ value: String) -> Bool {
	guard !value.isEmpty, value.contains(".") else { return false }
	return value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
}

@MainActor
public func shareItem(content: String, name: String? = nil, ext: String? = nil) -> Any {
	if let name {
		let suffix = ext.map { $0.isEmpty ? "" : ".\($0)" } ?? ""
		let fileName = name.sanitizedFilename() + suffix
		if let fileURL = writeToTempFile(named: fileName, content: content) {
			return fileURL
		}
	}
	return content
}

fileprivate func writeToTempFile(named: String, content: String) -> URL? {
	let tempDir = FileManager.default.temporaryDirectory
	let fileURL = tempDir.appendingPathComponent(named)
	do {
		try content.write(to: fileURL, atomically: true, encoding: .utf8)
		return fileURL
	} catch {
		return nil
	}
}

public struct CapturedAttachment {
	public let blob: Data
	public let utiType: String

	public init(blob: Data, utiType: String) {
		self.blob = blob
		self.utiType = utiType
	}
}

public protocol PhotoImport {
	var blob: Data { get }
	var photoName: String { get }
}

public extension PhotoImport where Self: DataAttachment {
	var photoName: String {
		sanitizedName
	}
}
