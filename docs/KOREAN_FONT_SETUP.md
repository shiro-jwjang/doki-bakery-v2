# Korean Font Setup for Doki-Doki Bakery v2

## Overview
This document describes the Korean font setup for web exports in Doki-Doki Bakery v2.

## Issue
- **Issue**: SNA-153 - Korean font rendering broken in web build
- **Symptom**: Korean text displays as square boxes in web builds
- **Root Cause**: Font files not imported by Godot

## Solution

### Font Files
- `assets/fonts/NotoSansKR-Regular.ttf` - Main Korean font (10MB)
- `assets/fonts/NotoColorEmoji.ttf` - Emoji font fallback
- `assets/fonts/NotoSansKR.tres` - FontFile resource with fallback configuration

### Import Configuration
- `assets/fonts/NotoSansKR-Regular.ttf.import` - Import configuration for Korean font
- `assets/fonts/NotoColorEmoji.ttf.import` - Import configuration for emoji font

### Theme Configuration
- `themes/default_theme.tres` - Default theme using NotoSansKR
- `project.godot` - Configured to use default_theme.tres

## Verification

### Manual Testing
1. Open project in Godot Editor
2. Export to Web platform
3. Test in browser with Korean text
4. Verify fonts display correctly

### Automated Testing
Run `test/test_font_setup.gd` to verify:
- Font file existence
- Font file size validation
- Theme resource loading
- Export configuration

## Web Export Settings
- Export filter: `all_resources`
- Include filters: `*.ttf,*.tres,*.otf`
- VRAM texture compression: Enabled for desktop

## Troubleshooting

### Font not appearing in web build
1. Verify `.import` files exist for font files
2. Check `export_presets.cfg` includes font extensions
3. Reimport fonts in Godot Editor
4. Clear `.godot/imported/` and reopen project

### Square boxes instead of Korean text
1. Check if NotoSansKR-Regular.ttf exists
2. Verify theme uses FontFile resource (.tres) not direct .ttf
3. Confirm import files have correct settings
4. Test font loading in editor first

## References
- Godot 4 Font Documentation: https://docs.godotengine.org/en/stable/tutorials/gui/gui_skinning.html
- Noto Fonts: https://fonts.google.com/noto
