import SwiftUI

public struct PendingAlert: Identifiable {
	public let id = UUID()
	public let alertable: any Alertable
	public let action: () -> Void

	public init(_ alertable: any Alertable, action: @escaping () -> Void) {
		self.alertable = alertable
		self.action = action
	}
}

public protocol Alertable {
	var title: String { get }
	var message: String { get }
	var primaryButtonTitle: String { get }
}
