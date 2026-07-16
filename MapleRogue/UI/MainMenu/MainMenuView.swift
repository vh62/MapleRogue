import SwiftUI

// Design source: MapleRogue Lobby.dc.html (Claude Design).
// Palette
private extension Color {
    static let mrYellow = Color(red: 1.0, green: 0.85, blue: 0.24)     // #ffd93d
    static let mrOrange = Color(red: 1.0, green: 0.62, blue: 0.11)     // #ff9f1c
    static let mrInkDark = Color(red: 0.10, green: 0.07, blue: 0.02)   // #1a1206
    static let mrBgTop = Color(red: 0.07, green: 0.13, blue: 0.10)     // #12211a
    static let mrBgMid = Color(red: 0.04, green: 0.08, blue: 0.05)     // #0a150e
    static let mrBgBottom = Color(red: 0.02, green: 0.05, blue: 0.03)  // #050d08
}

struct MainMenuView: View {

    enum LobbyTab {
        case shop, inventory, home, character, forge
    }

    @ObservedObject var profileVM: ProfileViewModel
    @State private var tab: LobbyTab = .home
    let onStartRun: () -> Void

    var body: some View {
        ZStack {
            LobbyBackground()
 
            VStack(spacing: 0) {
                switch tab {
                case .home:
                    HomeTab(profileVM: profileVM, onStartRun: onStartRun)
                case .shop:
                    ShopView(profileVM: profileVM)
                case .inventory:
                    LobbyPlaceholder(title: "Inventory",
                                     message: "Kept relics, equipment, and the starforce forge will live here.")
                case .character:
                    CharacterView(profileVM: profileVM)
                case .forge:
                    ForgeView(profileVM: profileVM)
                }

                LobbyTabBar(tab: $tab)
            }
        }
    }
}

// MARK: - Home tab

private struct HomeTab: View {

    @ObservedObject var profileVM: ProfileViewModel
    let onStartRun: () -> Void

    private var roomsCleared: Int { min(profileVM.profile.bestRoomCleared, 8) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 14)

            seasonRow
                .padding(.horizontal, 14)
                .padding(.top, 10)

            chapterTitle
                .padding(.top, 20)

            // Center: island flanked by the side rails.
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                    FloatingIsland()
                    rewardStrip
                        .padding(.top, 16)
                    Spacer()
                }

                HStack {
                    VStack(spacing: 16) {
                        RailButton(label: "Quests", locked: true) { QuestScrollIcon() }
                        RailButton(label: "Events", locked: true) { EventGiftIcon() }
                    }
                    Spacer()
                    VStack(spacing: 16) {
                        RailButton(label: "Shop", locked: false) { ShopBagIcon() }
                        RailButton(label: "Forge", locked: false) { ForgeGemIcon() }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(maxHeight: .infinity)

            chapterCard
                .padding(.horizontal, 18)

            StartRunButton(action: onStartRun)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
        }
    }

    // MARK: HUD row 1 — player + currencies

    private var topBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [Color(red: 1, green: 0.72, blue: 0.30), Color(red: 0.94, green: 0.50, blue: 0.07)],
                                       startPoint: .top, endPoint: .bottom))
                    Text("\(profileVM.profile.level)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color.mrInkDark)
                }
                .frame(width: 26, height: 26)

                Text("Adventurer")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .padding(.vertical, 5)
            .background(.black.opacity(0.4), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))

            Spacer()

            CurrencyChip(value: "\(profileVM.profile.mesos)") {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.88, blue: 0.4), Color(red: 0.91, green: 0.63, blue: 0.05)],
                                         center: .init(x: 0.35, y: 0.3), startRadius: 1, endRadius: 10))
                    .frame(width: 15, height: 15)
            }
            CurrencyChip(value: "\(profileVM.profile.gems)") {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color(red: 0.56, green: 0.94, blue: 1), Color(red: 0.15, green: 0.71, blue: 0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 13, height: 13)
                    .rotationEffect(.degrees(45))
            }
        }
    }

    // MARK: HUD row 2 — season banner + menu

    private var seasonRow: some View {
        HStack(spacing: 10) {
            Button {} label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(LinearGradient(colors: [.mrYellow, .mrOrange],
                                                 startPoint: .top, endPoint: .bottom))
                        Text("S1")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Color.mrInkDark)
                    }
                    .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("SEASON 1")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .kerning(0.5)
                            .foregroundStyle(Color.mrYellow)
                        ZStack(alignment: .leading) {
                            Capsule().fill(.black.opacity(0.45))
                            GeometryReader { geo in
                                Capsule()
                                    .fill(LinearGradient(colors: [.mrYellow, .mrOrange],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * 0.08)
                            }
                        }
                        .frame(height: 6)
                    }

                    Text("Lv 1")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(colors: [Color.mrYellow.opacity(0.16), Color.mrYellow.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mrYellow.opacity(0.3), lineWidth: 1))
                .overlay(ShineSweep(period: 3.5).clipShape(RoundedRectangle(cornerRadius: 14)))
            }

            Button {} label: {
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(.white.opacity(0.8)).frame(width: 18, height: 2.5)
                    }
                }
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 1))
                .overlay(alignment: .topTrailing) {
                    PulsingDot()
                        .offset(x: 4, y: -4)
                }
            }
        }
    }

    // MARK: Chapter title

    private var chapterTitle: some View {
        VStack(spacing: 6) {
            Text("1. Henesys Ruins")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color(red: 1, green: 0.89, blue: 0.48), .mrOrange],
                                   startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.mrOrange.opacity(0.35), radius: 10, y: 3)

            Text("\(roomsCleared) / 8 rooms cleared")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(.black.opacity(0.35), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }

    // MARK: Reward strip

    private var rewardStrip: some View {
        HStack(spacing: 12) {
            ChestIcon()

            (Text("Reach ").font(.system(size: 12, weight: .heavy, design: .rounded))
             + Text("room 8").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundColor(.mrYellow))
                .foregroundStyle(.white)
                .frame(alignment: .leading)
                .overlay(alignment: .bottomLeading) {
                    Text("Chapter chest")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .fixedSize()
                        .offset(y: 14)
                }
                .padding(.bottom, 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(.black.opacity(0.32), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: Chapter card

    private var chapterCard: some View {
        Button {} label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(LinearGradient(colors: [Color(red: 0.4, green: 0.73, blue: 0.42).opacity(0.5),
                                                      Color(red: 0.4, green: 0.73, blue: 0.42).opacity(0.12)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    LeafIcon()
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CHAPTER 1")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .kerning(1)
                        .foregroundStyle(Color.mrYellow)
                    Text("Henesys Ruins")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 7) {
                        ZStack(alignment: .leading) {
                            Capsule().fill(.black.opacity(0.45))
                            Capsule()
                                .fill(LinearGradient(colors: [.mrYellow, .mrOrange],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(2, 90 * CGFloat(roomsCleared) / 8))
                        }
                        .frame(width: 90, height: 6)
                        Text("\(roomsCleared) / 8 rooms")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// MARK: - Start button

private struct StartRunButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                Text("START RUN")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .kerning(0.5)
            }
            .foregroundStyle(Color.mrInkDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.mrYellow, .mrOrange], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 18))
            .overlay(ShineSweep(period: 2.8).clipShape(RoundedRectangle(cornerRadius: 18)))
            .shadow(color: Color.mrOrange.opacity(0.4), radius: 9, y: 6)
        }
        .buttonStyle(PressScaleStyle())
    }
}

private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Floating island

private struct FloatingIsland: View {

    @State private var floating = false
    @State private var bobbing = false

    var body: some View {
        VStack(spacing: -14) {
            ZStack {
                // Dirt underside
                Ellipse()
                    .fill(RadialGradient(colors: [Color(red: 0.42, green: 0.29, blue: 0.18),
                                                  Color(red: 0.20, green: 0.13, blue: 0.06)],
                                         center: .init(x: 0.5, y: 0.2), startRadius: 5, endRadius: 90))
                    .frame(width: 160, height: 56)
                    .offset(y: 62)

                // Grass platform
                Ellipse()
                    .fill(RadialGradient(colors: [Color(red: 0.4, green: 0.69, blue: 0.29),
                                                  Color(red: 0.25, green: 0.54, blue: 0.20),
                                                  Color(red: 0.17, green: 0.42, blue: 0.15)],
                                         center: .init(x: 0.5, y: 0.3), startRadius: 10, endRadius: 120))
                    .frame(width: 220, height: 84)
                    .offset(y: 34)

                // Trees
                TreeShape(color: Color(red: 0.18, green: 0.49, blue: 0.20), width: 32, height: 44)
                    .offset(x: -52, y: -8)
                TreeShape(color: Color(red: 0.22, green: 0.56, blue: 0.24), width: 40, height: 56)
                    .offset(x: 3, y: -18)
                TreeShape(color: Color(red: 0.26, green: 0.63, blue: 0.28), width: 28, height: 38)
                    .offset(x: 52, y: -2)

                // Flowers
                Circle().fill(Color.mrYellow).frame(width: 6).offset(x: -32, y: 30)
                Circle().fill(Color.mrYellow).frame(width: 5).offset(x: 32, y: 42)
                Circle().fill(Color(red: 1, green: 0.54, blue: 0.4)).frame(width: 5).offset(x: 62, y: 36)

                // Hero
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.69, blue: 0.4),
                                                      Color(red: 0.94, green: 0.50, blue: 0.07)],
                                             center: .init(x: 0.35, y: 0.3), startRadius: 3, endRadius: 24))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
                    Circle().fill(.white).frame(width: 8).offset(x: -3, y: -6)
                }
                .frame(width: 34, height: 34)
                .offset(x: -76, y: bobbing ? -32 : -23)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bobbing)
            }
            .frame(width: 250, height: 190)
            .offset(y: floating ? -9 : 0)
            .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: floating)

            // Ground shadow
            Ellipse()
                .fill(.black.opacity(0.4))
                .frame(width: 150, height: 22)
                .blur(radius: 8)
        }
        .onAppear {
            floating = true
            bobbing = true
        }
    }
}

private struct TreeShape: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(spacing: -2) {
            Triangle()
                .fill(color)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.36, green: 0.25, blue: 0.22))
                .frame(width: width * 0.25, height: height * 0.22)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Rail buttons + hand-drawn icons

private struct RailButton<Icon: View>: View {
    let label: String
    let locked: Bool
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button {} label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(LinearGradient(colors: [.white.opacity(0.13), .white.opacity(0.05)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.14), lineWidth: 1))
                        .shadow(color: .black.opacity(0.35), radius: 5, y: 4)
                    icon()
                }
                .frame(width: 52, height: 52)
                .overlay(alignment: .topTrailing) {
                    if locked {
                        Text("SOON")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .kerning(0.5)
                            .foregroundStyle(Color.mrInkDark)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(colors: [.mrYellow, Color(red: 1, green: 0.7, blue: 0.11)],
                                               startPoint: .top, endPoint: .bottom),
                                in: Capsule())
                            .offset(x: 8, y: -6)
                    }
                }

                Text(label)
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.6), radius: 3, y: 1)
            }
        }
        .buttonStyle(PressScaleStyle())
    }
}

private struct QuestScrollIcon: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Capsule().frame(width: 14, height: 2)
            Capsule().frame(width: 14, height: 2)
            Capsule().frame(width: 8, height: 2)
        }
        .foregroundStyle(Color(red: 0.35, green: 0.24, blue: 0.08).opacity(0.55))
        .padding(.horizontal, 4)
        .padding(.vertical, 5)
        .background(Color(red: 0.91, green: 0.85, blue: 0.69), in: RoundedRectangle(cornerRadius: 4))
    }
}

private struct EventGiftIcon: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.94))
                .frame(width: 24, height: 22)
            UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 0,
                                   bottomTrailingRadius: 0, topTrailingRadius: 5)
                .fill(Color(red: 1, green: 0.42, blue: 0.42))
                .frame(width: 24, height: 7)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.mrYellow.opacity(0.9))
                .frame(width: 5, height: 5)
                .offset(x: -6, y: 13)
        }
    }
}

private struct ShopBagIcon: View {
    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 6,
                                   bottomTrailingRadius: 6, topTrailingRadius: 4)
                .fill(LinearGradient(colors: [Color(red: 1, green: 0.82, blue: 0.37),
                                              Color(red: 0.91, green: 0.63, blue: 0.05)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 24, height: 20)
                .offset(y: 6)
            UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0,
                                   bottomTrailingRadius: 0, topTrailingRadius: 8)
                .stroke(Color(red: 0.91, green: 0.63, blue: 0.05), lineWidth: 2.5)
                .frame(width: 16, height: 9)
        }
        .frame(height: 26)
    }
}

private struct ForgeGemIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(LinearGradient(colors: [Color(red: 0.79, green: 0.64, blue: 1),
                                          Color(red: 0.48, green: 0.25, blue: 0.95)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(45))
            .shadow(color: Color(red: 0.63, green: 0.35, blue: 1).opacity(0.4), radius: 5)
    }
}

private struct ChestIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: [Color(red: 1, green: 0.82, blue: 0.37),
                                              Color(red: 0.78, green: 0.53, blue: 0.04)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 32, height: 24)
            Rectangle()
                .fill(Color(red: 0.47, green: 0.27, blue: 0).opacity(0.5))
                .frame(width: 32, height: 3)
                .offset(y: -3)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.54, green: 0.35, blue: 0))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(red: 1, green: 0.91, blue: 0.66), lineWidth: 1.5))
                .frame(width: 8, height: 9)
                .offset(y: -3)
        }
    }
}

private struct LeafIcon: View {
    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 24,
                               bottomTrailingRadius: 0, topTrailingRadius: 24)
            .fill(LinearGradient(colors: [Color(red: 0.51, green: 0.78, blue: 0.52),
                                          Color(red: 0.18, green: 0.49, blue: 0.20)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(-10))
    }
}

// MARK: - Shared lobby components

private struct CurrencyChip<Icon: View>: View {
    let value: String
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        HStack(spacing: 6) {
            icon()
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            ZStack {
                Circle().fill(.white.opacity(0.14))
                Text("+")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 15, height: 15)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.black.opacity(0.4), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

/// The moving highlight sweep from the design (mr-shine keyframes).
private struct ShineSweep: View {

    let period: Double
    @State private var sweep = false

    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, .white.opacity(0.35), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 60)
                .rotationEffect(.degrees(-20))
                .offset(x: sweep ? geo.size.width + 80 : -100)
                .animation(.easeInOut(duration: period).repeatForever(autoreverses: false),
                           value: sweep)
        }
        .allowsHitTesting(false)
        .onAppear { sweep = true }
    }
}

private struct PulsingDot: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(Color(red: 1, green: 0.3, blue: 0.3))
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.mrBgMid, lineWidth: 2))
            .scaleEffect(pulsing ? 1.35 : 1)
            .opacity(pulsing ? 0.7 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}

/// Dark green gradient with two slow-drifting glow orbs.
private struct LobbyBackground: View {

    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(stops: [.init(color: .mrBgTop, location: 0),
                                   .init(color: .mrBgMid, location: 0.55),
                                   .init(color: .mrBgBottom, location: 1)],
                           startPoint: .top, endPoint: .bottom)

            Circle()
                .fill(Color(red: 0.35, green: 0.78, blue: 0.47).opacity(0.13))
                .frame(width: 260)
                .blur(radius: 60)
                .offset(x: drift ? 20 : -40, y: drift ? -240 : -260)

            Circle()
                .fill(Color.mrYellow.opacity(0.09))
                .frame(width: 220)
                .blur(radius: 60)
                .offset(x: drift ? 50 : 110, y: drift ? 230 : 250)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: drift)
        .onAppear { drift = true }
    }
}

// MARK: - Placeholder tabs

private struct LobbyPlaceholder: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.mrYellow.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.mrYellow.opacity(0.25), lineWidth: 1))
                RoundedRectangle(cornerRadius: 7)
                    .fill(LinearGradient(colors: [Color(red: 1, green: 0.89, blue: 0.48), .mrOrange],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(45))
            }
            .frame(width: 76, height: 76)

            Text(title)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("COMING SOON")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .kerning(1)
                .foregroundStyle(Color.mrInkDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(colors: [.mrYellow, Color(red: 1, green: 0.7, blue: 0.11)],
                                   startPoint: .top, endPoint: .bottom),
                    in: Capsule())
                .padding(.top, 4)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Custom tab bar

private struct LobbyTabBar: View {

    @Binding var tab: MainMenuView.LobbyTab

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            barButton(.shop, label: "Shop") { active in
                ShopTabIcon(color: iconColor(active))
            }
            barButton(.inventory, label: "Inventory") { active in
                InventoryTabIcon(color: iconColor(active))
            }
            homeButton
            barButton(.character, label: "Character") { active in
                CharacterTabIcon(color: iconColor(active))
            }
            barButton(.forge, label: "Forge") { active in
                RoundedRectangle(cornerRadius: 4)
                    .fill(iconColor(active))
                    .frame(width: 15, height: 15)
                    .rotationEffect(.degrees(45))
                    .padding(.top, 5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [Color(red: 0.03, green: 0.07, blue: 0.04).opacity(0.9),
                                    Color(red: 0.02, green: 0.04, blue: 0.02).opacity(0.98)],
                           startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.08)).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func iconColor(_ active: Bool) -> Color {
        active ? .mrYellow : .white.opacity(0.4)
    }

    private func barButton<Icon: View>(_ target: MainMenuView.LobbyTab,
                                       label: String,
                                       @ViewBuilder icon: @escaping (Bool) -> Icon) -> some View {
        let active = tab == target
        return Button {
            tab = target
        } label: {
            VStack(spacing: 4) {
                icon(active)
                Text(label)
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(active ? Color.mrYellow : .white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(active ? Color.mrYellow.opacity(0.12) : .clear,
                        in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressScaleStyle())
    }

    /// Raised center Home button with the island icon.
    private var homeButton: some View {
        let active = tab == .home
        return Button {
            tab = .home
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: active
                                             ? [Color(red: 0.16, green: 0.29, blue: 0.20), Color(red: 0.09, green: 0.16, blue: 0.11)]
                                             : [Color(red: 0.11, green: 0.17, blue: 0.13), Color(red: 0.06, green: 0.10, blue: 0.07)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(active ? Color.mrYellow : .white.opacity(0.15), lineWidth: 2))
                        .shadow(color: .black.opacity(0.45), radius: 7, y: 6)

                    ZStack {
                        Ellipse()
                            .fill(active ? Color(red: 0.4, green: 0.69, blue: 0.29) : .white.opacity(0.35))
                            .frame(width: 28, height: 13)
                            .offset(y: 6)
                        Triangle()
                            .fill(active ? Color(red: 0.18, green: 0.49, blue: 0.20) : .white.opacity(0.55))
                            .frame(width: 12, height: 14)
                            .offset(y: -3)
                    }
                }
                .frame(width: 56, height: 56)

                Text("Home")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(active ? Color.mrYellow : .white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressScaleStyle())
        .offset(y: -14)
    }
}

private struct ShopTabIcon: View {
    let color: Color
    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 5,
                                   bottomTrailingRadius: 5, topTrailingRadius: 3)
                .fill(color)
                .frame(width: 22, height: 18)
                .offset(y: 5)
            UnevenRoundedRectangle(topLeadingRadius: 7, bottomLeadingRadius: 0,
                                   bottomTrailingRadius: 0, topTrailingRadius: 7)
                .stroke(color, lineWidth: 2)
                .frame(width: 15, height: 8)
        }
        .frame(height: 23)
    }
}

private struct InventoryTabIcon: View {
    let color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 24, height: 19)
            Rectangle()
                .fill(.black.opacity(0.35))
                .frame(width: 24, height: 2.5)
            RoundedRectangle(cornerRadius: 2)
                .fill(.black.opacity(0.35))
                .frame(width: 6, height: 7)
                .offset(y: -2)
        }
        .padding(.top, 4)
    }
}

private struct CharacterTabIcon: View {
    let color: Color
    var body: some View {
        VStack(spacing: 1.5) {
            Circle().fill(color).frame(width: 11, height: 11)
            UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 3,
                                   bottomTrailingRadius: 3, topTrailingRadius: 8)
                .fill(color)
                .frame(width: 20, height: 11)
        }
        .padding(.top, 2)
    }
}
