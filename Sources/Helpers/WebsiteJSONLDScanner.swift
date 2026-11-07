//
//  WebsiteJSONLDScanner.swift
//  ForkPlan
//

import Foundation

/// A bounded HTML tokenizer for JSON-LD script blocks, not a DOM or JavaScript engine.
/// Script contents are raw text: HTML entities inside JSON must not be decoded.
enum WebsiteJSONLDScanner {
    static func blocks(in html: String) -> [String] {
        let bytes = Array(html.utf8)
        var cursor = 0
        var blocks: [String] = []
        while cursor < bytes.count {
            guard bytes[cursor] == 60 else { cursor += 1; continue }
            if matches("<!--", at: cursor, in: bytes) {
                cursor = end(of: "-->", from: cursor + 4, in: bytes) ?? bytes.count
                continue
            }
            guard let tag = tag(at: cursor, in: bytes) else {
                // An unterminated real tag may contain quoted script-like text.
                if cursor + 1 < bytes.count, isName(bytes[cursor + 1]) { break }
                cursor += 1
                continue
            }
            cursor = tag.end
            guard !tag.closing else { continue }

            // Raw-text/RCDATA elements cannot contain real script tags.
            if ["script", "style", "textarea", "title", "xmp", "iframe", "noembed", "noframes"].contains(tag.name) {
                guard let closing = closingTag(named: tag.name, from: cursor, in: bytes) else { break }
                if tag.name == "script",
                   tag.attributes["src"] == nil,
                   tag.attributes["type"]?.split(separator: ";").first?
                    .trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "application/ld+json" {
                    blocks.append(String(decoding: bytes[cursor..<closing.start], as: UTF8.self))
                }
                cursor = closing.end
            } else if tag.name == "plaintext" {
                break
            }
        }
        return blocks
    }

    private struct Tag {
        var name: String
        var attributes: [String: String]
        var closing: Bool
        var end: Int
    }

    private static func tag(at start: Int, in bytes: [UInt8]) -> Tag? {
        var cursor = start + 1
        guard cursor < bytes.count else { return nil }
        let closing = bytes[cursor] == 47
        if closing { cursor += 1 }
        let nameStart = cursor
        while cursor < bytes.count, isName(bytes[cursor]) { cursor += 1 }
        guard cursor > nameStart else { return nil }
        let name = String(decoding: bytes[nameStart..<cursor], as: UTF8.self).lowercased()
        var attributes: [String: String] = [:]
        while cursor < bytes.count {
            while cursor < bytes.count, isSpace(bytes[cursor]) || bytes[cursor] == 47 { cursor += 1 }
            guard cursor < bytes.count else { return nil }
            if bytes[cursor] == 62 { return Tag(name: name, attributes: attributes, closing: closing, end: cursor + 1) }
            let attributeStart = cursor
            while cursor < bytes.count, !isSpace(bytes[cursor]), ![47, 61, 62].contains(bytes[cursor]) { cursor += 1 }
            guard cursor > attributeStart else { cursor += 1; continue }
            let attribute = String(decoding: bytes[attributeStart..<cursor], as: UTF8.self).lowercased()
            while cursor < bytes.count, isSpace(bytes[cursor]) { cursor += 1 }
            var value = ""
            if cursor < bytes.count, bytes[cursor] == 61 {
                cursor += 1
                while cursor < bytes.count, isSpace(bytes[cursor]) { cursor += 1 }
                guard cursor < bytes.count else { return nil }
                let quote = bytes[cursor]
                if quote == 34 || quote == 39 {
                    cursor += 1
                    let valueStart = cursor
                    while cursor < bytes.count, bytes[cursor] != quote { cursor += 1 }
                    guard cursor < bytes.count else { return nil }
                    value = String(decoding: bytes[valueStart..<cursor], as: UTF8.self)
                    cursor += 1
                } else {
                    let valueStart = cursor
                    while cursor < bytes.count, !isSpace(bytes[cursor]), bytes[cursor] != 62 { cursor += 1 }
                    value = String(decoding: bytes[valueStart..<cursor], as: UTF8.self)
                }
            }
            // HTML takes the first duplicate attribute, not the last.
            if attributes[attribute] == nil { attributes[attribute] = value }
        }
        return nil
    }

    private static func closingTag(named name: String, from start: Int, in bytes: [UInt8]) -> (start: Int, end: Int)? {
        var cursor = start
        while cursor < bytes.count {
            if bytes[cursor] == 60, matches("</" + name, at: cursor, in: bytes),
               let tag = tag(at: cursor, in: bytes), tag.closing, tag.name == name {
                return (cursor, tag.end)
            }
            cursor += 1
        }
        return nil
    }

    private static func end(of marker: String, from start: Int, in bytes: [UInt8]) -> Int? {
        var cursor = start
        while cursor < bytes.count {
            if matches(marker, at: cursor, in: bytes) { return cursor + marker.utf8.count }
            cursor += 1
        }
        return nil
    }

    private static func matches(_ text: String, at start: Int, in bytes: [UInt8]) -> Bool {
        let expected = Array(text.utf8)
        guard start + expected.count <= bytes.count else { return false }
        return expected.indices.allSatisfy { lowercase(bytes[start + $0]) == expected[$0] }
    }

    private static func lowercase(_ byte: UInt8) -> UInt8 { (65...90).contains(byte) ? byte + 32 : byte }
    private static func isName(_ byte: UInt8) -> Bool {
        (97...122).contains(lowercase(byte)) || (48...57).contains(byte) || byte == 45 || byte == 58
    }
    private static func isSpace(_ byte: UInt8) -> Bool { [9, 10, 12, 13, 32].contains(byte) }
}
