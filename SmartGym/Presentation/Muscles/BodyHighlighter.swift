//
//  BodyHighlighter.swift
//  SmartGym
//
//  Renders body SVG paths with muscle intensity highlighting. Use with BodyPathsLoader.
//

import SwiftUI

/// Muscle to highlight: slug (e.g. "chest", "upper-back") and intensity 1–3.
struct BodyMuscleData: Identifiable {
    let id = UUID()
    let slug: String
    let intensity: Int
}

struct BodyHighlighter: View {
    let muscles: [BodyMuscleData]
    let side: BodySide
    let gender: BodyGender
    var colors: [Color] = [
        AppColors.accentMint,
        AppColors.accentOrange,
        Color(hex: "ff3d3d")
    ]
    var borderColor: Color = AppColors.neutralDark

    private let viewBoxWidth: CGFloat = 570
    private let viewBoxHeight: CGFloat = 1390
    private let backTranslateX: CGFloat = -660
    private let nonMuscleSlugs = Set(["head", "hair", "neck", "feet", "ankles", "hands"])

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / viewBoxWidth, geo.size.height / viewBoxHeight)
            let tx = side == .back ? backTranslateX : 0
            let ox = (geo.size.width - viewBoxWidth * scale) / 2
            let oy = (geo.size.height - viewBoxHeight * scale) / 2
            let paths = BodyPathsLoader.paths(side: side, gender: gender)
            let slugOrder = orderedSlugs(from: paths)

            Canvas { ctx, _ in
                var transform = CGAffineTransform(translationX: ox + tx * scale, y: oy)
                    .scaledBy(x: scale, y: scale)
                for slug in slugOrder {
                    guard let set = paths[slug] else { continue }
                    let match = muscles.first { $0.slug == slug }
                    let style = colorFor(slug: slug, match: match)
                    let allPaths = set.left + set.right + set.common
                    for pathStr in allPaths where !pathStr.isEmpty {
                        let parsed = SVGPathParser.parse(pathStr)
                        let transformed = parsed.cgPath.copy(using: &transform) ?? parsed.cgPath
                        let path = Path(transformed)
                        ctx.fill(path, with: .color(style.fillColor))
                        if style.drawStroke {
                            ctx.stroke(path, with: .color(style.strokeColor), lineWidth: 1.5)
                        }
                    }
                }
            }
        }
    }

    private func orderedSlugs(from paths: [String: SluggedPathSet]) -> [String] {
        let keys = Array(paths.keys)
        let nonMuscle = keys.filter { nonMuscleSlugs.contains($0) }
        let muscle = keys.filter { !nonMuscleSlugs.contains($0) }
        return nonMuscle + muscle
    }

    private struct FillAndStroke {
        let fillColor: Color
        let strokeColor: Color
        let drawStroke: Bool
    }

    private func colorFor(slug: String, match: BodyMuscleData?) -> FillAndStroke {
        if nonMuscleSlugs.contains(slug) {
            switch slug {
            case "head", "neck": return FillAndStroke(fillColor: Color(hex: "c8906a"), strokeColor: Color(hex: "7a5538").opacity(0.5), drawStroke: true)
            case "hair": return FillAndStroke(fillColor: Color(hex: "2a1f14"), strokeColor: .clear, drawStroke: false)
            case "feet", "ankles", "hands": return FillAndStroke(fillColor: Color(hex: "b88060"), strokeColor: Color(hex: "7a5538").opacity(0.4), drawStroke: true)
            default: return FillAndStroke(fillColor: Color(hex: "1e2438"), strokeColor: borderColor, drawStroke: true)
            }
        }
        guard let m = match else {
            return FillAndStroke(fillColor: Color(hex: "1e2438"), strokeColor: borderColor, drawStroke: true)
        }
        let idx = min(max(m.intensity - 1, 0), colors.count - 1)
        let c = colors[idx]
        return FillAndStroke(fillColor: c.opacity(0.82), strokeColor: c.opacity(0.4), drawStroke: true)
    }
}
