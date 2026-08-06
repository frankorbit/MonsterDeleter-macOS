import SwiftUI
import UniformTypeIdentifiers

struct LandingView: View {
  @Bindable var store: LandingStore
  @State private var isDropTargeted = false

  var body: some View {
    VStack(spacing: 24) {
      hero
      dropZone
      extensionButton
    }
    .padding(32)
    .frame(minWidth: 560, minHeight: 430)
    .background(
      LinearGradient(
        colors: [Color(red: 0.04, green: 0.09, blue: 0.15), Color(red: 0.10, green: 0.19, blue: 0.27)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .preferredColorScheme(.dark)
  }

  private var hero: some View {
    VStack(spacing: 10) {
      Text("🦖")
        .font(.system(size: 64))
        .accessibilityHidden(true)
      Text("大将怪兽摧毁")
        .font(.system(size: 30, weight: .black, design: .rounded))
      Text("选中一个目标，然后告诉怪兽该往哪里踢。")
        .font(.body)
        .foregroundStyle(.secondary)
      Label("Finder 右键 → 快速操作/服务 → 召唤大将怪兽摧毁", systemImage: "checkmark.circle.fill")
        .font(.callout.weight(.medium))
        .foregroundStyle(.green)
    }
  }

  private var dropZone: some View {
    VStack(spacing: 14) {
      Image(systemName: "scope")
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(.red)
      Text("把文件或文件夹拖到这里")
        .font(.headline)
      Button(store.isChoosing ? "正在选择…" : "选择目标") {
        store.chooseTarget()
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(store.isChoosing)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(isDropTargeted ? Color.red.opacity(0.18) : Color.white.opacity(0.07))
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(isDropTargeted ? Color.red : Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 1.5, dash: [7]))
    }
    .dropDestination(for: URL.self) { urls, _ in
      guard let url = urls.first, url.isFileURL else { return false }
      store.start(with: url)
      return true
    } isTargeted: { targeted in
      isDropTargeted = targeted
    }
  }

  private var extensionButton: some View {
    Button("启用顶层 Finder 右键菜单（可选）") {
      store.openExtensionSettings()
    }
    .buttonStyle(.link)
    .foregroundStyle(.secondary)
    .help("macOS 要求用户手动授权 Finder 扩展；基础服务入口无需开启")
  }
}
