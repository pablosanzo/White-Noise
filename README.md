# White Noise App Build Instructions

## Linux Packaging
To package the app for transfer to macOS, run:
```bash
zip -r WhiteNoise.zip main.swift Info.plist
```

## macOS Setup
After transferring WhiteNoise.zip to your macOS system, run these commands in Terminal:
```bash
unzip WhiteNoise.zip
mkdir -p WhiteNoise.app/Contents/MacOS
swiftc main.swift -o WhiteNoise.app/Contents/MacOS/WhiteNoise
mkdir WhiteNoise.app/Contents
cp Info.plist WhiteNoise.app/Contents/
```

## Running the App
Double-click WhiteNoise.app in Finder to launch the application.

## Making Changes
1. Make your changes to main.swift or Info.plist
2. Re-run the Linux Packaging commands
3. On macOS, delete the old WhiteNoise.app and WhiteNoise.zip
4. Transfer the new WhiteNoise.zip and repeat the macOS Setup commands
