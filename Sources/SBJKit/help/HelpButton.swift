import SwiftUI
import WebKit
import ObjectiveC

extension AppInfo {
	public static let companyName = "Software by Jove"
	public static let supportEmail = "softwarebyjove@gmail.com"
}

public struct AssetPath: Equatable, Hashable {
	let title: String
	let folder: String
	let mainBundle: Bool

	public init(title: String, folder: String = "", mainBundle: Bool = true) {
		self.title = title
		self.folder = folder
		self.mainBundle = mainBundle
	}

	public var fullName: String {
		let assetName = title.sanitizeFileName(removeSpaces: true)
		let assetFullName = folder + "/" + assetName
		return assetFullName
	}

	public func stringValue() -> String? {
		let data: Data? =
			NSDataAsset(name: fullName, bundle: mainBundle ? .main : .module)?.data
		if let data, let stringValue = String(data: data, encoding: .utf8) {
			return stringValue
		}
		return nil
	}
}

public struct HelpButton: View {
	let asset: AssetPath
	let systemImage: String
	let auto: Bool
	let enabled: Bool
	let showAbout: Bool
	let substitutions: [String: String]

	static let hasAbout: Bool = AssetPath(title: "About", folder: "help", mainBundle: true).stringValue() != nil

	public init(
			asset: AssetPath,
			systemImage: String = "questionmark.circle",
			auto: Bool = true,
			enabled: Bool = true,
			showAbout: Bool = true,
			substitutions: [String : String] = [:],
			showHelp: Bool = false) {
		self.asset = asset
		self.systemImage = systemImage
		self.auto = auto
		self.enabled = enabled
		self.showAbout = showAbout && HelpButton.hasAbout
		self.substitutions = [
			"TITLE" : asset.title,
			"DISPLAY_NAME" : AppInfo.displayName,
			"VERSION" : AppInfo.fullVersion,
			"COMPANY_NAME" : AppInfo.companyName,
			"EMAIL" : AppInfo.supportEmail,
			"ICON" : AppInfo.icon?.pngData()?.base64EncodedString() ?? ""
			].merging(substitutions) { (_, new) in new }
		self.showHelp = showHelp
	}

	@State private var showHelp = false

	private var firstTimePresented: Bool {
		get {
			UserDefaults.standard.bool(forKey: asset.fullName) == true
		}
	}

	private func setFirstTimePresented() {
		UserDefaults.standard.set(true, forKey: asset.fullName)
	}

	public var body: some View {
		if enabled {
			ActionButton(systemImage.isEmpty ? asset.title : "Help", image: systemImage) {
				showHelp = true
			}
			.id(asset.title)
			.sheet(isPresented: $showHelp) {
				HelpSheet(
					asset: asset,
					substitutions: substitutions,
					showAbout: showAbout)
			}
			.onAppear {
				if auto && !firstTimePresented {
					setFirstTimePresented()
					showHelp = true
				}
			}
		}
	}
}
