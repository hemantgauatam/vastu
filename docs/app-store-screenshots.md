# Capture App Store screenshots in Codemagic

1. Open this app in Codemagic and switch to configuration from `codemagic.yaml`.
2. Start a build on `main` using **App Store screenshots (iPhone and iPad)**
   (`app-store-screenshots`). This separate workflow does not change your existing
   signed-release workflow and does not upload anything to Apple.
3. Download `store-screenshots.zip` from the build artifacts.
4. Review all six PNGs before uploading: check for loaded images, error messages,
   unexpected dialogs, clipped text and layout problems. A successful capture
   does not guarantee App Store approval.
5. Upload the `iphone` images to the matching large iPhone screenshot section and
   the `ipad` images to the 13-inch iPad section in App Store Connect.

The workflow captures the actual Home, Remedies and Discover screens, without
mocking content or resizing images. The manifest records device names and pixel
sizes. It requires a working production backend for Discover content and fails
if loading indicators remain or the output dimensions are unsupported.

It runs on Codemagic's Mac using iOS simulators; no signing credentials are
required. Camera and live compass screenshots need physical device hardware.
The default preferred devices are iPhone 16 Pro Max and iPad Pro 13-inch (M4),
with compatible alternatives selected if those models are unavailable.

Apple's accepted dimensions:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
