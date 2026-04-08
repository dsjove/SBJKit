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

// MARK: - Optional support

extension DefaultsStorage {
	public init<Wrapped>(
		wrappedValue defaultValue: Value = nil,
		_ key: String,
		store: UserDefaults = .standard
	) where Value == Optional<Wrapped>, Wrapped: DefaultsStorageValue {
		self.key = key
		self.store = store
		self.defaultValue = defaultValue
		self.getter = { defaults, key, defaultValue in
			Wrapped.read(from: defaults, key: key) ?? defaultValue
		}
		self.setter = { defaults, key, newValue in
			if let newValue {
				newValue.write(to: defaults, key: key)
			} else {
				defaults.removeObject(forKey: key)
			}
		}
	}

	public init<Wrapped>(
		wrappedValue defaultValue: Value = nil,
		_ key: String,
		store: UserDefaults = .standard
	) where Value == Optional<Wrapped>, Wrapped: RawRepresentable, Wrapped.RawValue: DefaultsStorageValue {
		self.key = key
		self.store = store
		self.defaultValue = defaultValue
		self.getter = { defaults, key, defaultValue in
			if let raw = Wrapped.RawValue.read(from: defaults, key: key) {
				if let wrapped = Wrapped(rawValue: raw) {
					return wrapped
				}
			}
			return defaultValue
		}
		self.setter = { defaults, key, newValue in
			if let newValue {
				newValue.rawValue.write(to: defaults, key: key)
			} else {
				defaults.removeObject(forKey: key)
			}
		}
	}
}

// MARK: - DefaultsStorageValue support

public protocol DefaultsStorageValue {
	static func read(from defaults: UserDefaults, key: String) -> Self?
	func write(to defaults: UserDefaults, key: String)
}

extension DefaultsStorage where Value: DefaultsStorageValue {
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

extension DefaultsStorage where Value: RawRepresentable, Value.RawValue: DefaultsStorageValue {
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
				if let raw = Value.RawValue.read(from: defaults, key: key) {
					if let wrapped = Value(rawValue: raw) {
						return wrapped
					}
				}
				return defaultValue
			},
			set: { defaults, key, newValue in
				newValue.rawValue.write(to: defaults, key: key)
			}
		)
	}
}

// MARK: - Native UserDefaults-supported types

extension Bool: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Bool? {
		defaults.object(forKey: key) as? Bool
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Int: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Int? {
		defaults.object(forKey: key) as? Int
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Double: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Double? {
		defaults.object(forKey: key) as? Double
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Float: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Float? {
		defaults.object(forKey: key) as? Float
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension String: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> String? {
		defaults.string(forKey: key)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Data: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Data? {
		defaults.data(forKey: key)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension UUID: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> UUID? {
		UUID(uuidString: defaults.object(forKey: key) as? String ?? "")
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self.uuidString, forKey: key)
	}
}

extension URL: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> URL? {
		defaults.url(forKey: key)
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}

extension Date: DefaultsStorageValue {
	public static func read(from defaults: UserDefaults, key: String) -> Date? {
		defaults.object(forKey: key) as? Date
	}

	public func write(to defaults: UserDefaults, key: String) {
		defaults.set(self, forKey: key)
	}
}
