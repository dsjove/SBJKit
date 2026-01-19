import Foundation
import Observation

public final class ObserveToken {
	private actor State {
		private var cancelled = false
		func setCancelled() { cancelled = true }
		func isCancelled() -> Bool { cancelled }
	}
	private let state = State()

	public init() {}

	public func cancel() {
		Task { await state.setCancelled() }
	}

	func isCancelled() async -> Bool {
		await state.isCancelled()
	}
}

@discardableResult
public func observeValue<S: AnyObject, C: AnyObject, V>(
		of src: S?,
		_ path: KeyPath<S, V>,
		with ctx: C? = nil,
		initialPush: Bool = true,
		change: @escaping (S, V, C?) -> Void) -> ObserveToken {
	guard let src else { return .init() }
	let hasContext = ctx != nil
	let token = ObserveToken()
	func track(src: S?, context: C?) {
		guard let src, let context else { return }
		withObservationTracking(
			/*apply:*/ { [weak weakSrc = src] in
				_ = weakSrc?[keyPath: path]
			},
			onChange: { [weak weakSrc = src, weak weakCtx = context] in
				Task {
					guard let strongSrc = weakSrc else { return }
					guard !(hasContext && weakCtx == nil) else { return }
					let strongCtx = weakCtx
					await MainActor.run {
						let value = strongSrc[keyPath: path]
						change(strongSrc, value, strongCtx)
					}
					if await token.isCancelled() { return }
					track(src: strongSrc, context: strongCtx)
				}
			}
		)
	}
	if initialPush {
		Task {
			if await token.isCancelled() { return }
			await MainActor.run { [weak weakSrc = src, weak weakCtx = ctx] in
				guard let strongSrc = weakSrc else { return }
				guard !(hasContext && weakCtx == nil) else { return }
				let strongCtx = weakCtx
				let value = strongSrc[keyPath: path]
				change(strongSrc, value, strongCtx)
			}
			if await token.isCancelled() { return }
			track(src: src, context: ctx)
		}
	} else {
		track(src: src, context: ctx)
	}
	return token
}
