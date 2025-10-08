# App Store Preview Video Specifications

Reference guide for creating App Store preview videos using ffmpeg.

## Requirements

### Duration
- **Minimum:** 15 seconds
- **Maximum:** 30 seconds

### Dimensions by Device Size

| Device Size | Dimensions (Portrait) | Dimensions (Landscape) |
|-------------|----------------------|------------------------|
| 6.9" (iPhone 16 Pro Max) | 1320 × 2868 | 2868 × 1320 |
| 6.7" (iPhone 15 Pro Max/Plus) | 1290 × 2796 | 2796 × 1290 |
| 6.5" (iPhone 11 Pro Max/XS Max) | 1284 × 2778 or 886 × 1920 | 2778 × 1284 or 1920 × 886 |
| 5.5" (iPhone 8 Plus) | 1242 × 2208 or 1080 × 1920 | 2208 × 1242 or 1920 × 1080 |

### Video Codec
- **Codec:** H.264
- **Profile:** High
- **Level:** 4.0 or lower (critical!)
- **Pixel Format:** yuv420p

### Audio
- **Optional:** Can be omitted entirely
- If included: Stereo AAC at 128 kbps

## FFmpeg Command

### Basic conversion (no audio, recommended):
```bash
ffmpeg -i input.mov \
  -vf "scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1" \
  -t 30 \
  -c:v libx264 \
  -profile:v high \
  -level:v 4.0 \
  -crf 18 \
  -preset slow \
  -pix_fmt yuv420p \
  -an \
  output.mov
```

### With audio:
```bash
ffmpeg -i input.mov \
  -vf "scale=886:1920:force_original_aspect_ratio=decrease,pad=886:1920:(ow-iw)/2:(oh-ih)/2,setsar=1:1" \
  -t 30 \
  -c:v libx264 \
  -profile:v high \
  -level:v 4.0 \
  -crf 18 \
  -preset slow \
  -pix_fmt yuv420p \
  -c:a aac \
  -b:a 128k \
  -ac 2 \
  output.mov
```

## Command Breakdown

- `-vf "scale=886:1920:..."` - Scales video to exact dimensions with padding
- `-t 30` - Trims video to 30 seconds max
- `-c:v libx264` - Uses H.264 codec
- `-profile:v high -level:v 4.0` - Sets correct profile/level for App Store
- `-crf 18` - Quality setting (lower = better quality, 18 is high quality)
- `-preset slow` - Encoding speed vs compression (slow = better compression)
- `-pix_fmt yuv420p` - Ensures compatibility
- `-an` - Removes audio entirely
- `-c:a aac -b:a 128k -ac 2` - Stereo AAC audio at 128 kbps (if using audio)

## Verification Commands

### Check video dimensions and codec info:
```bash
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,profile,level -of csv=p=0 video.mov
```

### Check duration:
```bash
mdls -name kMDItemDurationSeconds video.mov
```

### Check if audio exists:
```bash
ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 video.mov
```

## Common Issues

### "H264 level is too high"
- Solution: Add `-level:v 4.0` to command
- Default level is often 5.1, which App Store rejects

### "Unsupported or corrupted audio"
- Solution: Remove audio with `-an` flag
- App Store previews work perfectly without audio

### "Wrong dimensions"
- Solution: Use exact dimensions for target device size
- The `setsar=1:1` filter prevents dimension drift

## Recording from iOS Simulator

```bash
# Start recording
xcrun simctl io DEVICE_UUID recordVideo output.mov

# Stop recording (Ctrl+C or kill process)
pkill -INT simctl
```

## Notes

- App previews are **optional** - screenshots alone are sufficient
- You can add previews after initial app submission
- Preview videos autoplay in the App Store (iOS 11+)
- Consider creating versions for multiple device sizes

## Resources

- [Apple App Preview Specifications](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)

---

**Created:** October 2025
**For:** Tetrahedron iOS App Submission
