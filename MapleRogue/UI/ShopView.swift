import SwiftUI

private extension GearRarity {
    var shopColor: Color {
        switch self {
        case .common: Color(red: 0.55, green: 0.58, blue: 0.65)
        case .rare: Color(red: 0.29, green: 0.64, blue: 1.0)
        case .epic: Color(red: 0.72, green: 0.41, blue: 0.95)
        case .legendary: Color(red: 1.0, green: 0.70, blue: 0.22)
        }
    }
}

/// Shop tab: gear chests (functional meso/gem sinks) and gem packs
/// (display-only until StoreKit lands). All odds disclosed.
struct ShopView: View {

    @ObservedObject var profileVM: ProfileViewModel

    @State private var revealedItem: GearItem?
    @State private var toast: String?

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    chestSection
                    gemSection
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            if let toast {
                toastView(toast)
            }
        }
        .sheet(item: $revealedItem) { item in
            ChestRevealSheet(item: item) { revealedItem = nil }
                .presentationDetents([.height(280)])
                .presentationBackground(Color(red: 0.14, green: 0.17, blue: 0.30))
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Shop")
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Circle().fill(.yellow).frame(width: 12, height: 12)
                    Text("\(profileVM.profile.mesos)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.yellow)
                }
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.cyan)
                        .frame(width: 11, height: 11)
                        .rotationEffect(.degrees(45))
                    Text("\(profileVM.profile.gems)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.cyan)
                }
            }
        }
    }

    // MARK: - Chests

    private var chestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("GEAR CHESTS")

            ForEach(ChestType.allCases) { chest in
                chestCard(chest)
            }
        }
    }

    private func chestCard(_ chest: ChestType) -> some View {
        let gated = chest == .premium && !profileVM.isUnlocked(.premiumChest)
        let affordable = profileVM.canAfford(chest) && !gated
        let cost = chest.cost

        return VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(chest == .premium
                              ? AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.5), .purple.opacity(0.15)],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(.white.opacity(0.08)))
                    Image(systemName: chest == .premium ? "sparkles" : "shippingbox.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(chest == .premium ? .purple : .yellow)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(chest.name)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        if gated {
                            Text("🔒 Lv 6")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    oddsRow(chest)
                }

                Spacer()

                Button {
                    if let item = profileVM.openChest(chest) {
                        revealedItem = item
                    }
                } label: {
                    HStack(spacing: 4) {
                        if cost.mesos > 0 {
                            Circle().fill(.yellow).frame(width: 9, height: 9)
                            Text("\(cost.mesos)")
                        } else {
                            RoundedRectangle(cornerRadius: 2).fill(.cyan)
                                .frame(width: 8, height: 8).rotationEffect(.degrees(45))
                            Text("\(cost.gems)")
                        }
                    }
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(affordable ? .black : .white.opacity(0.35))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(affordable ? AnyShapeStyle(.yellow) : AnyShapeStyle(.white.opacity(0.08)),
                                in: Capsule())
                }
                .disabled(!affordable)
            }
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
    }

    private func oddsRow(_ chest: ChestType) -> some View {
        HStack(spacing: 8) {
            ForEach(chest.odds.filter { $0.weight > 0 }, id: \.rarity) { entry in
                HStack(spacing: 3) {
                    Circle().fill(entry.rarity.shopColor).frame(width: 6, height: 6)
                    Text("\(Int(entry.weight))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
    }

    // MARK: - Gem packs

    private var gemSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("GEMS")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(GemPack.all) { pack in
                    gemCard(pack)
                }
            }
        }
    }

    private func gemCard(_ pack: GemPack) -> some View {
        Button {
            showToast("Purchases arrive in a later build")
        } label: {
            VStack(spacing: 8) {
                if pack.bestValue {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.yellow, in: Capsule())
                } else {
                    Spacer().frame(height: 18)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(red: 0.56, green: 0.94, blue: 1),
                                                  Color(red: 0.15, green: 0.71, blue: 0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 26, height: 26)
                    .rotationEffect(.degrees(45))
                    .padding(.vertical, 6)

                Text("\(pack.gems) gems")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(pack.priceLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.9), in: Capsule())
            }
            .padding(12)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(pack.bestValue ? .yellow.opacity(0.6) : .white.opacity(0.1),
                        lineWidth: pack.bestValue ? 2 : 1))
        }
    }

    private var disclaimer: some View {
        Text("Chest odds shown above. Gem purchases are not yet enabled in this build.")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.35))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .kerning(1)
            .foregroundStyle(.white.opacity(0.5))
    }

    // MARK: - Toast

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(.black.opacity(0.85), in: Capsule())
            .padding(.top, 60)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Chest reveal

private struct ChestRevealSheet: View {

    let item: GearItem
    let onClose: () -> Void

    @State private var revealed = false

    var body: some View {
        VStack(spacing: 16) {
            Text(revealed ? item.rarity.displayName.uppercased() : "OPENING…")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .kerning(1.5)
                .foregroundStyle(revealed ? item.rarity.shopColor : .white.opacity(0.5))

            EquipSlotView(label: item.slot.rawValue,
                          rarity: item.rarity,
                          level: item.level,
                          size: 84)
                .scaleEffect(revealed ? 1 : 0.3)
                .opacity(revealed ? 1 : 0)

            if revealed {
                Text(item.name)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lv \(item.level)  ·  ⚔ +\(item.atkPercent)% ATK  ·  ♥ +\(item.bonusHP) HP")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Button(action: onClose) {
                Text("Nice!")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 11)
                    .background(.yellow, in: Capsule())
            }
            .opacity(revealed ? 1 : 0)
        }
        .padding(24)
        .onAppear {
            withAnimation(.bouncy(duration: 0.5).delay(0.4)) {
                revealed = true
            }
        }
    }
}
