# iOS Unsigned IPA Starter

Minimal SwiftUI project and GitHub Actions workflow for building an unsigned iOS IPA on a standard macOS runner.

## Build

Push a commit to `main`, or run **Build unsigned IPA** from the GitHub Actions tab. The workflow builds for `iphoneos` with code signing disabled and uploads `IPA-Starter-unsigned.ipa` as an artifact for seven days.

The generated IPA is unsigned and cannot be installed until it is signed with a provisioning profile and certificate that match the app's bundle identifier and entitlements.

## Customize

- Change the display name and bundle identifier in `IPAStarter.xcodeproj/project.pbxproj`.
- Replace `IPAStarter/ContentView.swift` with the app UI.
- Update the iOS deployment target in the project settings if needed.

## License

MIT
