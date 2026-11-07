# iOS Build Workflow

For native iOS app work in this repository:

- Use the existing GitHub Actions workflow on the standard `macos-15` runner to build with Xcode. Do not treat Linux Swift or Clang as a replacement for Apple's SDKs.
- Keep the build unsigned unless the user explicitly requests and provides a signing workflow. Never request or expose passwords, signing private keys, or access tokens in chat.
- Before relying on free compute, verify the repository is public and the standard GitHub-hosted macOS runner is being used. Do not enable paid runners or billing.
- Use the user's requested app name, bundle identifier, deployment target, and entitlements. The current `com.example.IPAStarter` identifier is only a starter placeholder; do not ship it as a real app without confirming or replacing it.
- After changes, trigger the workflow, inspect the result, and download and verify the IPA artifact when the user asks for a build.
- The unsigned IPA must contain `Payload/<AppName>.app` and must not include an embedded provisioning profile or code signature.
