import SwiftUI
import UIKit
import CoreGraphics

//TODO: refactor to eliminate duplicate code
public struct CroppingGesture: UIGestureRecognizerRepresentable {
	fileprivate var onChangedBlock: ((Value) -> Void)?
	fileprivate var onEndedBlock: ((Value) -> Void)?

	public func onChanged(_ action: @escaping (Value) -> Void) -> Self {
		var copy = self
		copy.onChangedBlock = action
		return copy
	}
	public func onEnded(_ action: @escaping (Value) -> Void) -> Self {
		var copy  = self
		copy.onEndedBlock = action
		return copy
	}

	public func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
		UIPinchGestureRecognizer(
			target: context.coordinator,
			action: #selector(Coordinator.handlePinch(_:))
		)
	}

	public func updateUIGestureRecognizer(_ recognizer: UIPinchGestureRecognizer, context: Context) {
	}

	public func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
		.init(
			onChanged: onChangedBlock,
			onEnded: onEndedBlock,
			converter: converter
		)
	}

	public struct Value: Equatable, Sendable {
		let numberOfTouches: Int
		let time: Date
		let state: UIGestureRecognizer.State
		let startLocation: CGPoint

		let location: CGPoint
		let translation: CGSize
		let scale: CGFloat
		let velocity: Double
		let rotation: Angle
	}

	public class Coordinator: NSObject {
		let onChanged: ((Value) -> Void)?
		let onEnded:   ((Value) -> Void)?
		let converter: CoordinateSpaceConverter

		init(
			onChanged: ((Value) -> Void)?,
			onEnded:   ((Value) -> Void)?,
			converter: CoordinateSpaceConverter
		) {
			self.onChanged = onChanged
			self.onEnded = onEnded
			self.converter = converter
		}

		private var startLocation: CGPoint?
		private var startVector: CGVector?
		private var startScale: CGFloat = 1.0
		private var lastRotation: Angle = .zero
		private var startedAsSingleFinger = false

		@MainActor @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
			guard let view = recognizer.view else { return }
			let uiLoc = recognizer.location(in: view)
			let loc = converter.convert(globalPoint: uiLoc, to: .local)

			switch recognizer.state {
			case .began:
				startLocation = loc
				startScale = 1.0
				lastRotation = .zero
				startVector = nil
				startedAsSingleFinger = recognizer.numberOfTouches == 1

				if recognizer.numberOfTouches >= 2 {
					let pt1 = recognizer.location(ofTouch: 0, in: view)
					let pt2 = recognizer.location(ofTouch: 1, in: view)
					startVector = CGVector(dx: pt2.x - pt1.x, dy: pt2.y - pt1.y)
				}

			case .changed:
				if startedAsSingleFinger && recognizer.numberOfTouches >= 2 {
					// Initialize rotation vector if not already done
					if startVector == nil {
						let pt1 = recognizer.location(ofTouch: 0, in: view)
						let pt2 = recognizer.location(ofTouch: 1, in: view)
						startVector = CGVector(dx: pt2.x - pt1.x, dy: pt2.y - pt1.y)
						lastRotation = .zero
					}
					startedAsSingleFinger = false
				}

				guard let start = startLocation else { return }
				let translation = CGSize(width: loc.x - start.x, height: loc.y - start.y)
				let scale = recognizer.scale

				var rotation = Angle.zero
				if recognizer.numberOfTouches >= 2, let startVector = startVector {
					let pt1 = recognizer.location(ofTouch: 0, in: view)
					let pt2 = recognizer.location(ofTouch: 1, in: view)
					let currentVector = CGVector(dx: pt2.x - pt1.x, dy: pt2.y - pt1.y)
					let startAngle = atan2(startVector.dy, startVector.dx)
					let currentAngle = atan2(currentVector.dy, currentVector.dx)
					let deltaAngle = currentAngle - startAngle
					rotation = .radians(deltaAngle)
					lastRotation = rotation
				} else {
					rotation = .zero
					lastRotation = .zero
				}

				let value = Value(
					numberOfTouches: recognizer.numberOfTouches,
					time: Date(),
					state: recognizer.state,
					startLocation: start,
					location: loc,
					translation: translation,
					scale: scale,
					velocity: recognizer.velocity,
					rotation: rotation
				)

				onChanged?(value)

			case .ended, .cancelled, .failed:
				guard let start = startLocation else { return }

				let translation = CGSize(width: loc.x - start.x, height: loc.y - start.y)
				let scale = recognizer.scale

				var rotation = Angle.zero
				if recognizer.numberOfTouches >= 2, let startVector = startVector {
					let pt1 = recognizer.location(ofTouch: 0, in: view)
					let pt2 = recognizer.location(ofTouch: 1, in: view)
					let currentVector = CGVector(dx: pt2.x - pt1.x, dy: pt2.y - pt1.y)
					let startAngle = atan2(startVector.dy, startVector.dx)
					let currentAngle = atan2(currentVector.dy, currentVector.dx)
					let deltaAngle = currentAngle - startAngle
					rotation = .radians(deltaAngle)
				}

				let value = Value(
					numberOfTouches: recognizer.numberOfTouches,
					time: Date(),
					state: recognizer.state,
					startLocation: start,
					location: loc,
					translation: translation,
					scale: scale,
					velocity: recognizer.velocity,
					rotation: rotation
				)

				onEnded?(value)

				startLocation = nil
				startVector = nil
				lastRotation = .zero
				startedAsSingleFinger = false
				startScale = 1.0

			default:
				break
			}
		}
	}
}
