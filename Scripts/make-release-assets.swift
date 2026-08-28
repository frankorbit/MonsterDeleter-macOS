#!/usr/bin/swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum AssetError: LocalizedError {
    case invalidArguments
    case unreadableImage(String)
    case renderFailed
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "Usage: make-release-assets.swift <source.png> <background.png> <iconset-dir>"
        case let .unreadableImage(path):
            return "Unable to read image: \(path)"
        case .renderFailed:
            return "Unable to render image"
        case let .writeFailed(path):
            return "Unable to write image: \(path)"
        }
    }
}

func renderAspectFill(_ source: CGImage, width: Int, height: Int, alpha: CGFloat) throws -> CGImage {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw AssetError.renderFailed
    }

    let scale = max(CGFloat(width) / CGFloat(source.width), CGFloat(height) / CGFloat(source.height))
    let scaledWidth = CGFloat(source.width) * scale
    let scaledHeight = CGFloat(source.height) * scale
    let destination = CGRect(
        x: (CGFloat(width) - scaledWidth) / 2,
        y: (CGFloat(height) - scaledHeight) / 2,
        width: scaledWidth,
        height: scaledHeight
    )

    context.interpolationQuality = .high
    context.setAlpha(alpha)
    context.draw(source, in: destination)

    guard let rendered = context.makeImage() else {
        throw AssetError.renderFailed
    }
    return rendered
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw AssetError.writeFailed(url.path)
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw AssetError.writeFailed(url.path)
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 3 else {
    throw AssetError.invalidArguments
}

let sourceURL = URL(fileURLWithPath: arguments[0])
let backgroundURL = URL(fileURLWithPath: arguments[1])
let iconsetURL = URL(fileURLWithPath: arguments[2])
let fileManager = FileManager.default

guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let source = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    throw AssetError.unreadableImage(sourceURL.path)
}

try fileManager.createDirectory(
    at: backgroundURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

// Finder uses the image at its native pixels, so match it to the DMG window exactly.
try writePNG(try renderAspectFill(source, width: 900, height: 780, alpha: 0.5), to: backgroundURL)

let iconSizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    try writePNG(
        try renderAspectFill(source, width: size, height: size, alpha: 1),
        to: iconsetURL.appendingPathComponent(name)
    )
}
