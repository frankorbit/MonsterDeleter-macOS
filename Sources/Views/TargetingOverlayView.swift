import SwiftUI

struct TargetingOverlayView: View {
  @Bindable var store: MonsterDeleterStore
  private let frameProvider: SpriteSheetFrameProviding

  init(
    store: MonsterDeleterStore,
    frameProvider: SpriteSheetFrameProviding = SpriteSheetFrameCache()
  ) {
    self.store = store
    self.frameProvider = frameProvider
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        Color.black.opacity(0.005)
          .allowsHitTesting(false)

        if store.phase == .targeting {
          targetingLayer(size: proxy.size)
            .transition(.opacity)
        }

        monsterLayer
        explosionLayer

        if store.showsConfirmation {
          confirmationLayer
        }

        if store.phase == .failed {
          failureLayer
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
    }
    .background(Color.clear)
  }

  private func targetingLayer(size: CGSize) -> some View {
    ZStack {
      if let image = backgroundImage {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
          .opacity(0.34)
      } else {
        Color.black.opacity(0.48)
      }

      Color.black.opacity(0.22)

      VStack(spacing: 12) {
        Text("请选择你要摧毁的文件")
          .font(.system(size: 34, weight: .black, design: .rounded))
        Text(store.target.displayName)
          .font(.title3.weight(.semibold))
          .lineLimit(1)
          .padding(.horizontal, 18)
          .padding(.vertical, 9)
          .background(.ultraThinMaterial, in: Capsule())
        Text("点击文件图标所在位置 · Esc 取消")
          .foregroundStyle(.secondary)
      }
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.65), radius: 10, y: 3)

      TargetingCursorView()
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { point in
          store.lockTarget(at: point, canvasSize: size)
        }
    }
    .frame(width: size.width, height: size.height)
  }

  @ViewBuilder
  private var monsterLayer: some View {
    if let animation = store.monsterAnimation {
      SpriteSheetView(
        animation: animation,
        displayHeight: store.monsterSize.height,
        frameProvider: frameProvider
      )
        .frame(width: store.monsterSize.width, height: store.monsterSize.height)
        .position(
          x: store.monsterPosition.x + store.monsterSize.width / 2,
          y: store.monsterPosition.y + store.monsterSize.height / 2
        )
        .task {
          do {
            try await Task.sleep(for: .milliseconds(100))
          } catch {
            return
          }

          guard !Task.isCancelled else { return }
          store.monsterDidAppear()
        }
    }
  }

  @ViewBuilder
  private var explosionLayer: some View {
    if let animation = store.explosionAnimation {
      SpriteSheetView(
        animation: animation,
        displayHeight: store.explosionSize.height,
        frameProvider: frameProvider
      )
        .frame(width: store.explosionSize.width, height: store.explosionSize.height)
        .position(
          x: store.targetPoint.x,
          y: store.targetPoint.y - 40
        )
        .allowsHitTesting(false)
    }
  }

  private var confirmationLayer: some View {
    VStack(spacing: 14) {
      Text("喂，是这个吗？")
        .font(.system(size: 21, weight: .bold, design: .rounded))
        .foregroundStyle(.black)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)

      HStack(spacing: 12) {
        Button("算了") {
          store.cancel()
        }
        .keyboardShortcut(.cancelAction)

        Button("是的，踢爆它") {
          store.confirmDestruction()
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .keyboardShortcut(.defaultAction)
      }
      .controlSize(.large)
    }
    .position(
      x: confirmationX,
      y: max(110, store.monsterPosition.y - 15)
    )
  }

  private var failureLayer: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 34))
        .foregroundStyle(.yellow)
      Text("怪兽没能移动这个目标")
        .font(.title2.bold())
      Text(store.errorMessage ?? "发生未知错误。")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 360)
      Button("返回") {
        store.cancel()
      }
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.defaultAction)
    }
    .padding(28)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(radius: 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var confirmationX: CGFloat {
    let desired = store.monsterPosition.x + store.monsterSize.width / 2
    return min(max(170, desired), max(170, store.canvasSize.width - 170))
  }

  private var backgroundImage: NSImage? {
    let url = Bundle.main.url(forResource: "targeting-background", withExtension: "png", subdirectory: "Images")
      ?? Bundle.main.url(forResource: "targeting-background", withExtension: "png")
    return url.flatMap(NSImage.init(contentsOf:))
  }
}
