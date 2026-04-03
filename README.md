# বিডিএআই (BDAi) — Flutter App

বাংলাদেশের নিজস্ব AI সহকারী অ্যাপ।

## Features
- ✅ ChatGPT-style chat UI — বাংলায়
- ✅ Smart intent detection (ছবি/এডিট/ফেস সোয়াপ auto-detect)
- ✅ Image generation, editing, face swap
- ✅ Voice input (STT) + Voice reply (TTS)
- ✅ Sidebar chat history
- ✅ Multi-session chat (localStorage)
- ✅ Dark/Light mode toggle
- ✅ Bengali ↔ English language switch
- ✅ Fake Google login (demo)
- ✅ Settings screen (no API URL shown)
- ✅ "বিডিএআই টেকনোলজি কর্তৃক নির্মিত"

## API Base URL
`http://103.7.4.121:5000`

## Build Steps

```bash
# Install dependencies
flutter pub get

# Run on device
flutter run

# Build APK
flutter build apk --release
```

## Font Setup (AdorshoLipi)
Currently using **Hind Siliguri** (Google Fonts) as Bengali font.

To use **AdorshoLipi** font:
1. Download `AdorshoLipi.ttf` from https://www.omicronlab.com/bangla-fonts.html
2. Place in `assets/fonts/` folder
3. Add to `pubspec.yaml`:
```yaml
fonts:
  - family: AdorshoLipi
    fonts:
      - asset: assets/fonts/AdorshoLipi.ttf
```
4. Replace `'HindSiliguri'` with `'AdorshoLipi'` in all dart files

## Package Name
`com.bdai.app`

## Made By
বিডিএআই টেকনোলজি কর্তৃক নির্মিত | Made by BDAi Technology
