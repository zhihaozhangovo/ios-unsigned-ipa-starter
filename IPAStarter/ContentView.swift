import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("iOS 构建环境已就绪")
                .font(.title2.weight(.semibold))

            Text("此示例由 GitHub Actions 在 macOS 上构建，并输出未签名 IPA。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
