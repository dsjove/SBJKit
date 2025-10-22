import SwiftData
import Foundation
import SwiftUI
internal import Combine
import CoreData

//This class is unusable right now

//We also want the spinner to present while
//the app is doing the initial load of a heavy
//preexisting set of data!

//We are seeing different threading used if we are in airplane mode
/*
struct SeedSyncOverlayModifier: ViewModifier {
	@ObservedObject var seedSync: CloudKitSeedSync

	func body(content: Content) -> some View {
		ZStack {
			content
				.disabled(seedSync.syncSate != .seeded)
			if seedSync.syncSate != .seeded {
				Color.black.opacity(0.15).ignoresSafeArea()
				ProgressView("Syncing…")
					.progressViewStyle(.circular)
			}
		}
	}
}

public extension View {
	public func seedSyncOverlay(_ seedSync: CloudKitSeedSync) -> some View {
		modifier(SeedSyncOverlayModifier(seedSync: seedSync))
	}
}

@Model
public final class SeedingStatus {
	// Existance means seeding
	// Existance and done means seeding is done
	var done: Bool = false
	init() {
	}
}

/// Defer call seeding until after a sync notification or timeout
@MainActor
public class CloudKitSeedSync: ObservableObject {
	private let context: ModelContext
	private let timeout: TimeInterval
	private let seeding: ()->()
	private let finished: ()->()
	private var remoteChangeObserver: AnyCancellable?
	private var fallbackTimer: Timer?

	@Published public var syncSate: SyncState = .pending

	public enum SyncState {
		case pending
		case seeding
		case seeded
	}

	enum NotificationSource {
		case bootstrap
		case cloudKit
		case timer
	}

	// Please do not call context save in seeding
	public init(_ context: ModelContext, timeout: TimeInterval = 3.0, seeding: @escaping ()->(), finished: @escaping ()->() = {}) {
		self.context = context
		self.timeout = timeout
		self.seeding = seeding
		self.finished = finished
		notified(.bootstrap)
	}

	private func notified(_ source: NotificationSource) {
		// Stop late notifications
		guard syncSate != .seeded else { return }
		let descriptor = FetchDescriptor<SeedingStatus>()
		let results = try? context.fetch(descriptor)
		// Always check if something is seeding
		if let marker = results?.first {
			print("CloudKitSeedSync: Detected sync object on \(source).")
			syncSate = .seeding
			// If a a sync object is done that means initial data is in.
			if marker.done {
				print("CloudKitSeedSync: marked as done from \(source).")
				defer {stopNotifications(source)}
				syncSate = .seeded
				finished()
			}
			// Still waiting for marker to be marked as done
			else if source == .timer {
				print("CloudKitSeedSync: External seeding has timed out.")
				// Hope for the best...
				defer {stopNotifications(source)}
				syncSate = .seeded
				finished()
			}
			// else still seeding
			return
		}

		print("CloudKitSeedSync: No sync object from \(source).")
		switch source {
			case .bootstrap:
				// On app start, start the notifications
				startNotifications(timeout)
				break
			case .cloudKit:
				// We will get several cloudKit notifications before we are done.
				break
			case .timer:
				print("CloudKitSeedSync: Seeding from \(source).")
				syncSate = .seeding
				defer {stopNotifications(.timer)}
				// Tell the world, including ourselves, that seeding has started
				let marker = SeedingStatus()
				context.insert(marker)
				try? context.save()
				seeding()
				// Tell the world, including ourselves, that seeding has stopped
				marker.done = true
				try? context.save()
				syncSate = .seeded
				finished()
				print("CloudKitSeedSync: Seeded from \(source).")
				break
		}
	}

	private func startNotifications(_ timeout: TimeInterval) {
		print("CloudKitSeedSync: Starting notifications.")
		self.context.autosaveEnabled = false
		remoteChangeObserver = NotificationCenter.default
			.publisher(for: .NSPersistentStoreRemoteChange)
			.sink { [weak self] _ in
				DispatchQueue.main.async {
					self?.notified(.cloudKit)
				}
			}
		fallbackTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
			DispatchQueue.main.async {
				self?.notified(.timer)
			}
		}
	}

	private func stopNotifications(_ source: NotificationSource) {
		print("CloudKitSeedSync: Stopping notifications from \(source).")
		defer { context.autosaveEnabled = true }
		remoteChangeObserver?.cancel()
		remoteChangeObserver = nil
		fallbackTimer?.invalidate()
		fallbackTimer = nil
	}
}
*/
