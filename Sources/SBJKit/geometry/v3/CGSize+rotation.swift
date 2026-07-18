import CoreGraphics



public extension CGSize {
    /// Returns the resulting size for the given rotation and scale mode.
    /// - Parameters:
    ///   - angleRadians: Rotation angle in radians.
    ///   - mode: `.fit` for inscribed rect, `.fill` for bounding rect.
    /// - Returns: The computed size.
    func rotatedSize(angleRadians: CGFloat, mode: ScaleMode) -> CGSize {
        switch mode {
        case .fit:
            return rotatedInscribed(angleRadians: angleRadians)
        case .fill:
            return rotatedBounding(angleRadians: angleRadians)
        }
    }

    /// Scaling behavior for computing rect after rotation.
    /// Returns the axis-aligned bounding box size of this size when rotated by the given angle in radians.
    /// - Parameter angleRadians: Rotation angle in radians.
    /// - Returns: The size of the bounding rectangle that contains the rotated rectangle.
    func rotatedBounding(angleRadians: CGFloat) -> CGSize {
        let w = width
        let h = height
        if w <= 0 || h <= 0 { return .zero }
        let a = sanitizeAngle(angleRadians)
        let c = abs(cos(a))
        let s = abs(sin(a))
        let bw = w * c + h * s
        let bh = w * s + h * c
        return CGSize(width: bw, height: bh)
    }

    /// Returns the size of the largest axis-aligned rectangle that fits entirely within this size after rotating by the given angle.
    /// This corresponds to a "fit" behavior.
    /// - Parameter angleRadians: Rotation angle in radians.
    /// - Returns: The size of the maximal inscribed axis-aligned rectangle.
    func rotatedInscribed(angleRadians: CGFloat) -> CGSize {
        let W = width
        let H = height
        if W <= 0 || H <= 0 { return .zero }
        var a = sanitizeAngle(angleRadians)
        // Normalize to [0, pi/2]
        a = abs(a).truncatingRemainder(dividingBy: .pi)
        if a > .pi / 2 { a = .pi - a }
        if a == 0 { return CGSize(width: W, height: H) }

        let sinA = abs(sin(a))
        let cosA = abs(cos(a))

        // Using the known closed form solution for the largest axis-aligned rectangle inside a rotated rectangle
        let denomWidth = (cosA * cosA) / W + (sinA * sinA) / H
        let denomHeight = (cosA * cosA) / H + (sinA * sinA) / W

        // Compute widthFit and heightFit using more stable formulas:
        // Reference: https://math.stackexchange.com/questions/91132/how-to-get-size-of-a-rotated-rectangle-to-fit-inside-another-rectangle
        let widthFit = min(
            W,
            (W * H) / (H * cosA + W * sinA)
        )
        let heightFit = min(
            H,
            (W * H) / (W * cosA + H * sinA)
        )

        if widthFit.isNaN || heightFit.isNaN || widthFit <= 0 || heightFit <= 0 {
            return .zero
        }
        return CGSize(width: widthFit, height: heightFit)
    }

    // MARK: - Helpers

    /// Returns 0 for NaN or infinite angles to keep computations stable.
    private func sanitizeAngle(_ a: CGFloat) -> CGFloat {
        if a.isNaN || !a.isFinite { return 0 }
        return a
    }

    /// Returns the four corners of this size's rectangle after rotation by the given angle around a center point.
    /// The size represents a rectangle centered at `center` with width `width` and height `height`.
    /// - Parameters:
    ///   - angleRadians: Rotation angle in radians.
    ///   - center: The center point about which to rotate. Defaults to `.zero`.
    /// - Returns: An array of four CGPoints in clockwise order starting from top-left (unrotated frame).
    func rotatedCorners(angleRadians: CGFloat, center: CGPoint = .zero) -> [CGPoint] {
        let w = width
        let h = height
        if w <= 0 || h <= 0 { return [CGPoint](repeating: center, count: 4) }
        let a = sanitizeAngle(angleRadians)
        let c = CGFloat(cos(a))
        let s = CGFloat(sin(a))
        let hx = w / 2
        let hy = h / 2

        // Unrotated corners relative to center (CoreGraphics y-down): top-left, top-right, bottom-right, bottom-left
        let corners = [
            CGPoint(x: -hx, y: -hy),
            CGPoint(x:  hx, y: -hy),
            CGPoint(x:  hx, y:  hy),
            CGPoint(x: -hx, y:  hy)
        ]

        // Apply rotation: (x', y') = (x*c - y*s, x*s + y*c)
        let rotated = corners.map { p -> CGPoint in
            let rx = p.x * c - p.y * s
            let ry = p.x * s + p.y * c
            return CGPoint(x: center.x + rx, y: center.y + ry)
        }
        return rotated
    }
}
