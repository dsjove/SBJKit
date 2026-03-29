import Foundation

@propertyWrapper
public struct DefaultsStorage<Value> {
	private let key: String
	private let store: UserDefaults
	private let defaultValue: Value
	private let getter: (UserDefaults, String, Value) -> Value
	private let setter: (UserDefaults, String, Value) -> Void

	public var wrappedValue: Value {
		get { getter(store, key, defaultValue) }
		nonmutating set { setter(store, key, newValue) }
	}

	public init(
		wrappedValue defaultValue: Value,
		_ key: String,
		store: UserDefaults = .standard,
		get: @escaping (UserDefaults, String, Value) -> Value,
		set: @escaping (UserDefaults, String, Value) -> Void
	) {
		self.key = key
		self.store = store
		self.defaultValue = defaultValue
		self.getter = get
		self.setter = set
	}
}

// MARK: - SettingsStorageValueCompatible support

public protocol SettingsStorageValueCompatible {
	static func read(from defaults: UserDefaults, key: String) -> Self?
	func write(to defaults: UserDefaults, key: String)
}

extension DefaultsStorage where Value: SettingsStorageValueCompatible {
	public init(
		wrappedValue defaultValue: Value,
		_ key: String,
		store: UserDefaults = .standard
	) {
		self.init(
			wrappedValue: defaultValue,
			key,
			store: store,
			get: { defaults, key, defaultValue in
				Value.read(from: defaults, key: key) ?? defaultValue
			},
			set: { defaults, key, newValue in
				newValue.write(to: defaults, key: key)
			}
		)
	}
}

// MARK: - RawRepresentable support

extension DefaultsStorage where Value: RawRepresentable, Value.RawValue: SettingsStorageValueCompatible {
	public init(
		wrappedValue defaultValue: Value,
		_ key: String,
		store: UserDefaults = .standard
	) {
		self.init(
			wrappedValue: defaultValue,
			key,
			store: store,
			get: { defaults, key, defaultValue in
				guard let raw = Value.RawValue.read(from: defaults, key: key) else {
					return defaultValue
				}
				return Value(rawValue: raw) ?? defaultValue
			},
			set: { defaults, key, newValue in
				newValue.rawValue.write(to: defaults, key: key)
			}
		)
	}
}

// MARK: - Native UserDefaults-supported types

extension Bool: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> Bool? {
		defaults.object(forKey: key) as? Bool
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Int: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> Int? {
		defaults.object(forKey: key) as? Int
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Double: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> Double? {
		defaults.object(forKey: key) as? Double
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Float: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> Float? {
		defaults.object(forKey: key) as? Float
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension String: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> String? {
		defaults.string(forKey: key)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Data: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> Data? {
		defaults.data(forKey: key)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension URL: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> URL? {
		defaults.url(forKey: key)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Date: SettingsStorageValueCompatible {
	public static func read(from defaults: UserDefaults, key: String) -> Date? {
		defaults.object(forKey: key) as? Date
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}
