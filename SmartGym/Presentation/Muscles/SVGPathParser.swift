//
//  SVGPathParser.swift
//  SmartGym
//
//  Parses SVG path "d" strings (M, m, L, l, C, c, Q, q, Z, z) into SwiftUI Path.
//

import SwiftUI

enum SVGPathParser {
    /// Parse full SVG path string (absolute and relative commands) into Path.
    static func parse(_ svg: String) -> Path {
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero
        let tokens = tokenize(svg)
        var i = 0
        var currentCommand: Character?

        func isCommandToken(_ token: String) -> Bool {
            guard let c = token.first else { return false }
            return c.isLetter
        }

        while i < tokens.count {
            let token = tokens[i]
            if isCommandToken(token) {
                currentCommand = token.first
                i += 1
            }
            guard let cmdChar = currentCommand else {
                i += 1
                continue
            }

            let isRelative = cmdChar.isLowercase
            let base = Character(cmdChar.uppercased())

            switch base {
            case "M":
                // First pair is a move, any additional pairs are implicit lines.
                if let pt = point(tokens, &i) {
                    if isRelative { current.x += pt.x; current.y += pt.y } else { current = pt }
                    start = current
                    path.move(to: current)
                }
                while i + 1 < tokens.count, !isCommandToken(tokens[i]) {
                    if let pt = point(tokens, &i) {
                        if isRelative { current.x += pt.x; current.y += pt.y } else { current = pt }
                        path.addLine(to: current)
                    } else {
                        break
                    }
                }
            case "L":
                while i + 1 < tokens.count, !isCommandToken(tokens[i]) {
                    if let pt = point(tokens, &i) {
                        if isRelative { current.x += pt.x; current.y += pt.y } else { current = pt }
                        path.addLine(to: current)
                    } else {
                        i += 1
                        break
                    }
                }
            case "C":
                while i + 5 < tokens.count, !isCommandToken(tokens[i]) {
                    guard let c1 = point(tokens, &i),
                          let c2 = point(tokens, &i),
                          let ep = point(tokens, &i) else { i += 1; break }
                    var p1 = c1, p2 = c2, end = ep
                    if isRelative {
                        p1 = CGPoint(x: current.x + c1.x, y: current.y + c1.y)
                        p2 = CGPoint(x: current.x + c2.x, y: current.y + c2.y)
                        end = CGPoint(x: current.x + ep.x, y: current.y + ep.y)
                    }
                    current = end
                    path.addCurve(to: current, control1: p1, control2: p2)
                }
            case "Q":
                while i + 3 < tokens.count, !isCommandToken(tokens[i]) {
                    guard let cp = point(tokens, &i),
                          let ep = point(tokens, &i) else { i += 1; break }
                    var control = cp, end = ep
                    if isRelative {
                        control = CGPoint(x: current.x + cp.x, y: current.y + cp.y)
                        end = CGPoint(x: current.x + ep.x, y: current.y + ep.y)
                    }
                    current = end
                    path.addQuadCurve(to: current, control: control)
                }
            case "Z":
                path.closeSubpath()
                current = start
            case "H":
                while i < tokens.count, !isCommandToken(tokens[i]), let val = Double(tokens[i]) {
                    i += 1
                    if isRelative { current.x += val } else { current.x = val }
                    path.addLine(to: current)
                }
            case "V":
                while i < tokens.count, !isCommandToken(tokens[i]), let val = Double(tokens[i]) {
                    i += 1
                    if isRelative { current.y += val } else { current.y = val }
                    path.addLine(to: current)
                }
            case "A":
                while i + 6 < tokens.count, !isCommandToken(tokens[i]) {
                    i += 7
                }
                if i < tokens.count, !isCommandToken(tokens[i]) {
                    while i < tokens.count, !isCommandToken(tokens[i]) { i += 1 }
                }
            default:
                i += 1
            }
        }
        return path
    }

    private static func point(_ t: [String], _ i: inout Int) -> CGPoint? {
        guard i + 1 < t.count, let x = Double(t[i]), let y = Double(t[i + 1]) else { return nil }
        i += 2
        return CGPoint(x: x, y: y)
    }

    private static func tokenize(_ s: String) -> [String] {
        let cmds = Set("MLQCZHVAamlqczhv")
        var result: [String] = []
        var cur = ""
        for ch in s {
            if cmds.contains(ch) {
                flush(&cur, into: &result)
                result.append(String(ch))
            } else if ch == "," || ch == " " {
                flush(&cur, into: &result)
            } else if (ch == "-" || ch == "+") && !cur.isEmpty && cur.last?.isNumber == true {
                flush(&cur, into: &result)
                cur.append(ch)
            } else {
                cur.append(ch)
            }
        }
        flush(&cur, into: &result)
        return result
    }

    private static func flush(_ cur: inout String, into result: inout [String]) {
        let t = cur.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { result.append(t) }
        cur = ""
    }
}
