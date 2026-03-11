# Export Guide - Doki-Doki Bakery

## Prerequisites

### Export Templates

Export templates must be installed before building. Run this in Godot Editor:

1. **Editor → Manage Export Templates**
2. Click **Download and Install**

Or manually download from:
https://github.com/godotengine/godot/releases/tag/4.6.1-stable

### Template Locations

Templates should be installed to:
```
~/.local/share/godot/export_templates/4.6.1.stable/
```

Required templates for each platform:
- **Linux**: linux_debug.x86_64, linux_release.x86_64
- **Windows**: windows_debug.x86_64.exe, windows_release.x86_64.exe
- **macOS**: macos_debug.universal.zip, macos_release.universal.zip
- **Web**: web_nothreads_debug.zip, web_nothreads_release.zip

## Build Commands

### Linux
```bash
godot --headless --export-release "Linux/X11" builds/linux/doki-bakery
```

### Windows
```bash
godot --headless --export-release "Windows Desktop" builds/windows/doki-bakery.exe
```

### macOS
```bash
godot --headless --export-release "macOS" builds/mac/doki-bakery.zip
```

### Web (Itch.io)
```bash
godot --headless --export-release "Web" builds/web/index.html
```

## Itch.io Deployment

### Web Build
1. Export Web build to `builds/web/`
2. Upload entire `builds/web/` directory to Itch.io
3. Set **This file will be played in the browser** checkbox
4. Configure viewport size: 1200×1000

### Desktop Builds
1. Export platform-specific builds
2. Create ZIP archives for each platform
3. Upload to Itch.io with appropriate platform tags

## Export Configuration

Current export presets are configured in `export_presets.cfg`:

| Platform | Runnable | Output Path |
|----------|----------|-------------|
| Linux/X11 | ✅ | builds/linux/doki-bakery |
| Windows Desktop | ✅ | builds/windows/doki-bakery.exe |
| macOS | ❌ | builds/mac/doki-bakery.zip |
| Web | ✅ | builds/web/index.html |

### Notes
- **macOS**: Not configured for code signing (runnable=false)
- **Web**: Includes TTF/OTF fonts
- All platforms: BPTC and S3TC texture formats enabled

## Troubleshooting

### "No export template found"
- Install export templates (see Prerequisites)
- Verify Godot version matches template version (4.6.1)

### "SCRIPT ERROR" during export
- Run `./scripts/qa-check.sh` to identify issues
- Fix all type errors before exporting

### Large file size
- Enable texture compression in export presets
- Use VRAM compression for desktop platforms
- Consider stripping debug symbols for release builds
