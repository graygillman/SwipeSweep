//
//  DynamicProgress.swift
//  DynamicProgressView
//

import SwiftUI
import Combine

// MARK: - Observable controller

class DynamicProgress: NSObject, ObservableObject {
    
    @Published var isAdded: Bool = false
    @Published var hideStatusBar: Bool = false

    private var overlayWindow: UIWindow?

    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic  = UIImpactFeedbackGenerator(style: .heavy)

    override init() {
        super.init()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
    }

    func addProgressView(config: ProgressConfig) {
        guard overlayWindow == nil else { print("ALREADY ADDED"); return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        window.overrideUserInterfaceStyle = scene.traitCollection.userInterfaceStyle

        let rootVC = TransparentHostingController(
            rootView: DynamicProgressView(config: config).environmentObject(self)
        )
        rootVC.view.backgroundColor = .clear
        window.rootViewController = rootVC
        window.makeKeyAndVisible()

        overlayWindow = window
        isAdded = true

        DispatchQueue.main.async { self.hideStatusBar = true }
    }

    func updateProgressView(to value: CGFloat) {
        NotificationCenter.default.post(
            name: .init("UPDATE_PROGRESS"), object: nil,
            userInfo: ["progress": value]
        )
    }

    func triggerMilestone() {
        mediumHaptic.impactOccurred()
        mediumHaptic.prepare()
        NotificationCenter.default.post(name: .init("MILESTONE_HIT"), object: nil)
    }

    func triggerGrandMilestone() {
        heavyHaptic.impactOccurred(intensity: 1.0)
        heavyHaptic.prepare()
        NotificationCenter.default.post(name: .init("GRAND_MILESTONE_HIT"), object: nil)
    }

    func resetForNextBlock() {
        NotificationCenter.default.post(name: .init("RESET_PROGRESS"), object: nil)
    }

    func removeProgressView() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
        isAdded = false
        hideStatusBar = false
    }

    func removeProgressWithAnimations() {
        NotificationCenter.default.post(name: .init("CLOSE_PROGRESS_VIEW"), object: nil)
    }
}

// MARK: - Transparent root controller

private final class TransparentHostingController<Content: View>: UIHostingController<Content> {
    override var prefersStatusBarHidden: Bool { true }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
}

// MARK: - Dynamic Island overlay view

fileprivate struct DynamicProgressView: View {
    var config: ProgressConfig
    @EnvironmentObject var progressBar: DynamicProgress

    @State private var showProgressView: Bool = false
    @State private var progress: CGFloat = 0
    @State private var showAlertView: Bool = false
    @State private var showMilestoneCheck: Bool = false
    @State private var litBars: Int = 0

    var body: some View {
        Canvas { ctx, size in
            ctx.addFilter(.alphaThreshold(min: 0.5, color: .black))
            ctx.addFilter(.blur(radius: 5.5))
            ctx.drawLayer { context in
                for index in [1, 2] {
                    if let resolved = ctx.resolveSymbol(id: index) {
                        context.draw(resolved, at: CGPoint(x: size.width / 2, y: 11 + 18))
                    }
                }
            }
        } symbols: {
            ProgressComponents().tag(1)
            ProgressComponents(isCircle: true).tag(2)
        }
        .opacity(showAlertView ? 0 : 1)
        .animation(.easeOut(duration: 0.2), value: showAlertView)
        .overlay(alignment: .top) { ProgressRing().offset(y: 11) }
        .overlay(alignment: .top) { SignalBars().offset(y: 16) }
        .overlay(alignment: .top) { CustomAlertView() }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showProgressView = true }
        }
        // Manual close
        .onReceive(NotificationCenter.default.publisher(for: .init("CLOSE_PROGRESS_VIEW"))) { _ in
            showProgressView = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { progressBar.removeProgressView() }
        }
        // Regular 100-swipe milestone — checkmark flash + light up a bar
        .onReceive(NotificationCenter.default.publisher(for: .init("MILESTONE_HIT"))) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                litBars = min(litBars + 1, 4)
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { showMilestoneCheck = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { showMilestoneCheck = false }
            }
        }
        // Grand 500-swipe milestone
        .onReceive(NotificationCenter.default.publisher(for: .init("GRAND_MILESTONE_HIT"))) { _ in
            withAnimation(.spring(response: 0.3)) { litBars = 5 }
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                showProgressView = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showAlertView = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                showAlertView = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    progress = 0
                    litBars = 0
                    showMilestoneCheck = false
                    progressBar.resetForNextBlock()
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7)) {
                        showProgressView = true
                    }
                }
            }
        }
        // External reset
        .onReceive(NotificationCenter.default.publisher(for: .init("RESET_PROGRESS"))) { _ in
            progress = 0
            litBars = 0
        }
        // Normal ring progress
        .onReceive(NotificationCenter.default.publisher(for: .init("UPDATE_PROGRESS"))) { output in
            guard let info = output.userInfo,
                  let value = info["progress"] as? CGFloat else { return }
            if !showMilestoneCheck && !showAlertView {
                progress = min(value, 0.999)
            }
        }
    }

    // MARK: Progress ring (gooey blob, right of island)
    @ViewBuilder
    func ProgressRing() -> some View {
        ZStack {
            let clamped = max(0, min(1, progress))
            Image(systemName: showMilestoneCheck ? "checkmark" : config.progressImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.semibold)
                .frame(width: 12, height: 12)
                .foregroundColor(showMilestoneCheck ? .green : config.tint)
                .rotationEffect(.init(degrees: config.rotationEnabled && !showMilestoneCheck
                                      ? Double(clamped * 360) : 0))
                .animation(.spring(response: 0.3), value: showMilestoneCheck)

            ZStack {
                Circle().stroke(.white.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: showMilestoneCheck ? 1.0 : progress)
                    .stroke(
                        showMilestoneCheck ? Color.green : config.tint,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.init(degrees: -90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.65), value: showMilestoneCheck)
                    .animation(.easeOut(duration: 0.15), value: progress)
            }
            .frame(width: 23, height: 23)
        }
        .frame(width: 37, height: 37)
        .frame(width: 126, alignment: .trailing)
        .offset(x: showProgressView ? 45 : 0)
        .opacity(showProgressView ? 1 : 0)
        .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7), value: showProgressView)
    }

    // MARK: Signal bars (far right of screen)
    @ViewBuilder
    func SignalBars() -> some View {
        let heights: [CGFloat] = [6, 9, 12, 15, 18]

        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(i < litBars ? config.tint : Color.gray.opacity(0.5))
                    .frame(width: 3.5, height: heights[i])
                    .scaleEffect(y: i < litBars ? 1 : 0.8, anchor: .bottom)
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.6)
                            .delay(Double(i) * 0.04),
                        value: litBars
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 24)
        .opacity(showProgressView ? 1 : 0)
        .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7), value: showProgressView)
    }

    // MARK: Congrats banner
    @ViewBuilder
    func CustomAlertView() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            Capsule()
                .fill(.black)
                .frame(width:  showAlertView ? size.width : 125,
                       height: showAlertView ? size.height : 35)
                .overlay {
                    HStack(spacing: 13) {
                        Image(systemName: config.expandedImage)
                            .symbolRenderingMode(.multicolor)
                            .font(.largeTitle)
                            .foregroundStyle(.white, .blue, .white)

                        HStack(spacing: 6) {
                            Text(config.completionTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text(config.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .lineLimit(1)
                        .contentTransition(.opacity)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(y: 12)
                    }
                    .padding(.horizontal, 12)
                    .blur(radius: showAlertView ? 0 : 5)
                    .opacity(showAlertView ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 65)
        .padding(.horizontal, 18)
        .offset(y: showAlertView ? 59 : 12)
        .animation(
            .interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.7)
                .delay(showAlertView ? 0.35 : 0),
            value: showAlertView
        )
    }

    // MARK: Canvas blob shapes
    @ViewBuilder
    func ProgressComponents(isCircle: Bool = false) -> some View {
        if isCircle {
            Circle()
                .fill(.black)
                .frame(width: 37, height: 37)
                .frame(width: 126, alignment: .trailing)
                .offset(x: showProgressView ? 45 : 0)
                .scaleEffect(showProgressView ? 1 : 0.55, anchor: .trailing)
                .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7), value: showProgressView)
        } else {
            Capsule()
                .fill(.black)
                .frame(width: 126, height: 36)
                .offset(y: 1)
        }
    }
}
