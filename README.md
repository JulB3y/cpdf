# cpdf - PDF Compression for macOS

<p align="center">
  <img src="cpdf/Assets.xcassets/AppIcon.appiconset/cpdf_icon_2.png" width="128" height="128">
</p>

A lightweight, native macOS application for efficient PDF compression. Built with SwiftUI, cpdf offers an intuitive interface for reducing PDF file sizes while maintaining reasonable quality.

## Key Features

- 🎯 Simple drag & drop interface
- 🔧 Multiple compression levels
  - High (Original quality)
  - Minimal (1440p)
  - Light (1080p)
  - Medium (720p)
  - Strong (480p)
- 🎨 Color mode options
  - Full color space
  - Grayscale
- 🌍 Multilingual support (English, German)
- 💻 Native macOS experience
- 🔒 Privacy focused - all processing happens locally

## Screenshots

<p align="center">
  <img src="screenshots/mainview.png" width="720">
</p>
<p align="center">
  <img src="screenshots/settingsview.png" width="720">
</p>
<p align="center">
  <img src="screenshots/compressedview.png" width="720">
</p>

## Installation

1. Download the latest version from the [Releases](https://github.com/JulB3y/cpdf/releases) page
2. Open the downloaded DMG file
3. Drag cpdf to your Applications folder
4. Launch cpdf from Applications

## System Requirements

- macOS 13.0 or later
- Apple Silicon or Intel processor
- Approximately 50MB of disk space

## Quick Start

1. Launch cpdf
2. Drop a PDF file into the window or click "Select PDF"
3. Adjust compression settings if needed
4. The compressed PDF will be saved automatically

## Advanced Settings

### Compression Quality
- **High**: Optimizes the PDF without visible quality loss
- **Minimal (1440p)**: Perfect for high-quality presentations and documents with many images
- **Light (1080p)**: Best for documents with high-quality images
- **Medium (720p)**: Good balance between size and quality
- **Strong (480p)**: Maximum compression, suitable for basic documents

### Color Modes
- **Full Color Space**: Preserves original color information
- **Grayscale**: Converts to grayscale for smaller file sizes

## Development

Built with modern Apple technologies and best practices.

### Requirements

- Xcode 15.0 or later
- macOS 13.0 SDK
- Swift 5.9

### Building from Source
1. Clone the repository
2. Open the project in Xcode
3. Build and run the project

## Credits
- [CompressPDF](https://github.com/OpenToolKit/CompressPDF)
