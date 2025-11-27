import Foundation
import SwiftData

public protocol DefaultsValue {
	associatedtype RawValue: DefaultsValue
	var defaultsValue: RawValue? { get }

	init?(defaults: RawValue)
}

public extension DefaultsValue where Self == RawValue {
	var defaultsValue: Self? { get { self } }
}

public extension DefaultsValue where Self == RawValue, Self: Equatable {
	init?(defaults: RawValue) { self = defaults }
}

extension String: DefaultsValue {}
extension Date: DefaultsValue {}
extension Int: DefaultsValue {}
extension Double: DefaultsValue {}
extension Bool: DefaultsValue {}
extension Data: DefaultsValue {}

extension Array: DefaultsValue {
	public init?(defaults: Array<Element>) { self = defaults }
}

extension Dictionary: DefaultsValue {
	public init?(defaults: Dictionary<Key, Value>) { self = defaults }
}

public extension RawRepresentable where Self.RawValue: DefaultsValue {
	var defaultsValue: RawValue? { rawValue }
	init?(defaults: RawValue) { self = .init(rawValue: defaults)! }
}

extension Optional: DefaultsValue where Wrapped: DefaultsValue {
	public var defaultsValue: Wrapped.RawValue? {
		switch self {
			case .none: return nil
			case .some(let wrapped): return wrapped.defaultsValue
		}
	}
	public init?(defaults: Wrapped.RawValue) {
		guard let value: Wrapped = .init(defaults: defaults) else { return nil }
		self = .some(value)
	}
}

extension UUID: DefaultsValue {
	public var defaultsValue: String? { uuidString }
	public init?(defaults: String) { self.init(uuidString: defaults) }
}

@propertyWrapper
public struct SettingsStorage<Value: DefaultsValue> {
	let key: String
	let defaultValue: Value
	let container: UserDefaults

	public init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
		self.key = key
		self.defaultValue = defaultValue
		self.container = container
	}

	public init<Wrapped>(key: String, container: UserDefaults = .standard) where Value == Optional<Wrapped>, Wrapped: DefaultsValue {
		self.key = key
		self.defaultValue = .none
		self.container = container
	}

	public var wrappedValue: Value {
		get {
			let raw = container.object(forKey: key)
			let rawValue = raw as? Value.RawValue
			if let rawValue {
				if let value = Value(defaults: rawValue) {
					return value
				}
			}
			return defaultValue
		}
		set {
			container.set(newValue.defaultsValue, forKey: key)
		}
	}
}
