import UIKit

public enum AppInfo {
	public static var displayName: String {
		Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
		?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
		?? "Unknown App"
	}

	public static var version: String {
		Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
	}

	public static var build: String {
		Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
	}

	public static var fullVersion: String {
		"\(version) (\(build))"
	}

	public static var bundleIdentifier: String {
		Bundle.main.bundleIdentifier ?? "Unknown"
	}

	public static var icon: UIImage? {
		guard
			let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
			let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
			let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
			let lastIcon = iconFiles.last
		else {
			return nil
		}
		return UIImage(named: lastIcon)
	}
}
