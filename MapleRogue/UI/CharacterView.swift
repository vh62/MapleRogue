import SwiftUI

// Design source: Character Tab.dc.html (Claude Design).
// Palette
private extension Color {
    static let ctBg = Color(red: 0.11, green: 0.14, blue: 0.25)        // #1c2340
    static let ctPanel = Color(red: 0.08, green: 0.10, blue: 0.19)     // #141a30
    static let ctSheet = Color(red: 0.14, green: 0.17, blue: 0.30)     // #232b4d
    static let ctYellow = Color(red: 1.0, green: 0.82, blue: 0.25)     // #ffd23f
    static let ctGreen = Color(red: 0.25, green: 0.82, blue: 0.49)     // #3fd17e
    static let ctGreenLight = Color(red: 0.49, green: 0.91, blue: 0.53) // #7ee787
    static let ctSkyTop = Color(red: 0.56, green: 0.83, blue: 0.96)    // #8fd3f4
    static let ctSkyMid = Color(red: 0.65, green: 0.89, blue: 1.0)     // #a6e3ff
    static let ctSkyBottom = Color(red: 0.84, green: 0.94, blue: 1.0)  // #d7f0ff
}

private extension GearRarity {
    var color: Color {
        switch self {
        case .common: Color(red: 0.55, green: 0.58, blue: 0.65)     // #8b95a6
        case .rare: Color(red: 0.29, green: 0.64, blue: 1.0)        // #4aa3ff
        case .epic: Color(red: 0.72, green: 0.41, blue: 0.95)       // #b869f2
        case .legendary: Color(red: 1.0, green: 0.70, blue: 0.22)   // #ffb238
        }
    }
}

/// Character tab: equipped hero panel, equipment grid, presets.
/// Class selection lives in the "Class" sub-tab.
struct CharacterView: View {

    private enum SubTab: String, CaseIterable {
        case equip = "Equip"
        case cash = "Cash"
        case pet = "Pet"
        case add = "Add"
    }

    @ObservedObject var profileVM: ProfileViewModel

    @State private var subTab: SubTab = .equip
    @State private var selectedItem: GearItem?
    @State private var selectionIsEquipped = false
    @State private var toast: String?

    var body: some View {
        ZStack(alignment: .top) {
            Color.ctBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                heroPanel
                statChips
                subTabBar
                content
                presetBar
            }

            if let toast {
                toastView(toast)
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemSheet(item: item,
                      isEquipped: selectionIsEquipped,
                      mesos: profileVM.profile.mesos,
                      canWear: profileVM.canWear(item),
                      powerDelta: profileVM.power(with: item) - profileVM.power,
                      onEquip: {
                          if profileVM.equip(item) {
                              showToast("\(item.name) equipped!")
                          }
                          selectedItem = nil
                      },
                      onUpgrade: {
                          if profileVM.upgradeGear(item) {
                              showToast("\(item.name) upgraded to Lv \(item.level + 1)!")
                          }
                          selectedItem = nil
                      },
                      onClose: { selectedItem = nil })
                .presentationDetents([.height(430)])
                .presentationBackground(Color.ctSheet)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.ctYellow, Color(red: 0.88, green: 0.48, blue: 0.22)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2), lineWidth: 2))
                        .overlay(
                            Text(classInitials)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.23, green: 0.16, blue: 0)))
                        .frame(width: 42, height: 42)

                    Text("\(profileVM.profile.level)")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.02, green: 0.13, blue: 0.06))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.ctGreen, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.04, green: 0.23, blue: 0.12), lineWidth: 1.5))
                        .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Adventurer")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(profileVM.profile.xp) / \(profileVM.xpToNextLevel) XP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    GeometryReader { geo in
                        Capsule()
                            .fill(LinearGradient(colors: [.ctGreen, .ctGreenLight],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * profileVM.xpProgress)
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                currencyPill(color: .ctYellow, value: profileVM.profile.mesos)
                currencyPill(color: Color(red: 0.29, green: 0.64, blue: 1.0), value: profileVM.profile.gems)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color.ctPanel)
    }

    private var classInitials: String {
        profileVM.selectedClass.name.split(separator: " ").compactMap(\.first).map(String.init).joined()
    }

    private func currencyPill(color: Color, value: Int) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Hero panel (sky background, 3 slots each side)

    private var heroPanel: some View {
        HStack(spacing: 4) {
            slotColumn(GearSlot.allCases.prefix(3))

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.6), lineWidth: 2))
                // Placeholder — real character art drops in here.
                heroPlaceholder
            }
            .frame(width: 128, height: 150)

            slotColumn(GearSlot.allCases.suffix(3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(
            LinearGradient(stops: [.init(color: .ctSkyTop, location: 0),
                                   .init(color: .ctSkyMid, location: 0.45),
                                   .init(color: .ctSkyBottom, location: 1)],
                           startPoint: .top, endPoint: .bottom))
    }

    private var heroPlaceholder: some View {
        let heroClass = profileVM.selectedClass
        return VStack(spacing: 6) {
            Circle()
                .fill(Color(red: heroClass.color.r, green: heroClass.color.g, blue: heroClass.color.b))
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .overlay(Circle().fill(.white).frame(width: 10).offset(x: -4, y: -8))
                .frame(width: 56, height: 56)
            Text(heroClass.name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0, green: 0.16, blue: 0.24).opacity(0.6))
        }
    }

    private func slotColumn(_ slots: ArraySlice<GearSlot>) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(slots), id: \.self) { slot in
                let item = profileVM.equippedItem(in: slot)
                Button {
                    if let item {
                        selectionIsEquipped = true
                        selectedItem = item
                    }
                } label: {
                    EquipSlotView(label: slot.rawValue,
                                  rarity: item?.rarity,
                                  level: item?.level,
                                  size: 56)
                }
            }
        }
    }

    // MARK: - Stat chips

    private var statChips: some View {
        let heroClass = profileVM.selectedClass
        let atk = heroClass.baseDamage + heroClass.baseDamage * profileVM.gearAtkPercent / 100
        let hp = heroClass.maxHP + profileVM.gearBonusHP

        return HStack(spacing: 10) {
            statChip("⚡ \(profileVM.power) POWER")
            statChip("⚔ \(atk) ATK")
            statChip("♥ \(hp) HP")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [.ctSkyBottom, Color(red: 0.76, green: 0.90, blue: 0.98)],
                           startPoint: .top, endPoint: .bottom))
    }

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.ctPanel.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Sub-tabs

    private var subTabBar: some View {
        HStack(spacing: 8) {
            ForEach(SubTab.allCases, id: \.self) { tab in
                Button {
                    subTab = tab
                    selectedItem = nil
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(subTab == tab ? Color(red: 0.23, green: 0.16, blue: 0) : .white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(subTab == tab ? AnyShapeStyle(Color.ctYellow) : AnyShapeStyle(.white.opacity(0.08)),
                                    in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.ctPanel)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch subTab {
        case .equip:
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(profileVM.profile.gearInventory) { item in
                        Button {
                            selectionIsEquipped = false
                            selectedItem = item
                        } label: {
                            EquipSlotView(label: item.slot.rawValue,
                                          rarity: item.rarity,
                                          level: item.level,
                                          size: 54)
                        }
                    }
                }
                .padding(14)
            }
            .frame(maxHeight: .infinity)

        case .cash, .pet:
            emptyState(subTab == .cash ? "No cash items yet" : "No pet equipment yet")

        case .add:
            // Gear acquisition entry point — wired to drops/shop when they land.
            emptyState("New gear comes from boss drops and the Shop — coming soon")
        }
    }

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(width: 56, height: 56)
                .overlay(Text("+").font(.system(size: 22)).foregroundStyle(.white.opacity(0.25)))
            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preset bar

    private var presetBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("PRESET")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                if !profileVM.isUnlocked(.presets) {
                    Text("🔒 Lv 5")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                ForEach(0..<3, id: \.self) { index in
                    Button {
                        guard profileVM.isUnlocked(.presets) || index == 0 else {
                            showToast("Presets unlock at Lv 5")
                            return
                        }
                        profileVM.switchPreset(to: index)
                        showToast("Preset \(index + 1) loaded")
                    } label: {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(profileVM.profile.activePresetIndex == index
                                             ? Color(red: 0.23, green: 0.16, blue: 0) : .white.opacity(0.6))
                            .frame(width: 26, height: 26)
                            .background(profileVM.profile.activePresetIndex == index
                                        ? AnyShapeStyle(Color.ctYellow) : AnyShapeStyle(.white.opacity(0.1)),
                                        in: Circle())
                    }
                }
            }

            Spacer()

            Button {
                showToast("Preset \(profileVM.profile.activePresetIndex + 1) applied!")
            } label: {
                Text("Apply")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.02, green: 0.13, blue: 0.06))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(colors: [.ctGreenLight, .ctGreen],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.ctPanel)
    }

    // MARK: - Toast

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.ctGreenLight)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.ctPanel.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ctGreenLight.opacity(0.4), lineWidth: 1))
            .padding(.top, 72)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(20)
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Equip slot (design's EquipSlot component)

struct EquipSlotView: View {

    let label: String
    let rarity: GearRarity?
    let level: Int?
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(rarity.map { AnyShapeStyle($0.color.opacity(0.22)) }
                      ?? AnyShapeStyle(.black.opacity(0.25)))
            RoundedRectangle(cornerRadius: 14)
                .stroke(rarity?.color ?? .white.opacity(0.25),
                        style: rarity == nil
                            ? StrokeStyle(lineWidth: 2, dash: [5])
                            : StrokeStyle(lineWidth: 2))

            Text(label)
                .font(.system(size: size * 0.2, weight: .heavy, design: .rounded))
                .foregroundStyle(rarity == nil ? .white.opacity(0.3) : .white.opacity(0.9))

            if let level {
                Text("\(level)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(rarity?.color ?? .gray, in: RoundedRectangle(cornerRadius: 5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 3, y: 3)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Item detail sheet

private struct ItemSheet: View {

    let item: GearItem
    let isEquipped: Bool
    let mesos: Int
    let canWear: Bool
    let powerDelta: Int
    let onEquip: () -> Void
    let onUpgrade: () -> Void
    let onClose: () -> Void

    private var canAffordUpgrade: Bool {
        mesos >= item.upgradeCost
    }

    /// 20 stars in groups of five, filled by enhancement level.
    private var starRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { group in
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        let star = group * 5 + index
                        Image(systemName: star < item.stars ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(star < item.stars ? .yellow : .white.opacity(0.25))
                    }
                }
            }
        }
    }

    private func statLine(label: String, total: String, base: Int, stars: Int,
                          potential: Int, suffix: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label) :")
                .foregroundStyle(.white.opacity(0.6))
            Text(total)
                .foregroundStyle(.white)
            (Text("(\(base)\(suffix)")
                .foregroundColor(.white.opacity(0.5))
             + Text(stars > 0 ? " +\(stars)\(suffix)" : "")
                .foregroundColor(.orange)
             + Text(potential > 0 ? " +\(potential)\(suffix)" : "")
                .foregroundColor(Color.ctGreenLight)
             + Text(")")
                .foregroundColor(.white.opacity(0.5)))
        }
        .font(.system(size: 13, weight: .bold, design: .rounded))
    }

    var body: some View {
        VStack(spacing: 12) {
            // ★ Star row — enhancement state first, MapleStory-style.
            starRow

            // Name + rarity, centered like the classic tooltip.
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(item.rarity.color)
                Text(item.rarity.displayName.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .kerning(1)
                    .foregroundStyle(item.rarity.color.opacity(0.7))
            }

            HStack(alignment: .top, spacing: 14) {
                EquipSlotView(label: item.slot.rawValue,
                              rarity: item.rarity,
                              level: item.level,
                              size: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("REQ LEV : \(item.requiredLevel)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(canWear ? .white.opacity(0.6) : Color(red: 1, green: 0.45, blue: 0.4))
                    Text("Item Type : \(item.slot.rawValue.capitalized)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    if isEquipped {
                        HStack(spacing: 4) {
                            Circle().fill(.yellow).frame(width: 8, height: 8)
                            Text("\(mesos) mesos")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(canAffordUpgrade ? .white.opacity(0.7) : Color(red: 1, green: 0.45, blue: 0.4))
                        }
                    }
                }
                Spacer()
            }

            Divider().overlay(.white.opacity(0.15))

            // Stat breakdown: total (base +stars +potential), sources colored.
            VStack(alignment: .leading, spacing: 5) {
                statLine(label: "ATK",
                         total: "+\(item.atkPercent)%",
                         base: item.level * item.rarity.statMultiplier / 2,
                         stars: item.starforceAtkPercent,
                         potential: item.potentialTotal(.pctATK),
                         suffix: "%")
                statLine(label: "MaxHP",
                         total: "+\(item.bonusHP)",
                         base: item.level * item.rarity.statMultiplier,
                         stars: item.starforceBonusHP,
                         potential: item.potentialTotal(.flatHP),
                         suffix: "")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().overlay(.white.opacity(0.15))

            // Potential section — the gamble results get their own home.
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.ctGreen)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(45))
                    Text("Potential")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.ctGreenLight)
                }
                if item.potentialLines.isEmpty {
                    Text("None — use a cube in the Forge to unlock")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    ForEach(item.potentialLines) { line in
                        HStack(spacing: 5) {
                            if line.isPrime {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.yellow)
                            }
                            Text(line.stat.format(line.value))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(line.isPrime ? .yellow : Color.ctGreenLight)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isEquipped && powerDelta != 0 {
                Text(powerDelta > 0 ? "Equip: +\(powerDelta) Power" : "Equip: \(powerDelta) Power")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(powerDelta > 0 ? Color.ctGreenLight : Color(red: 1, green: 0.45, blue: 0.4))
            }

            HStack(spacing: 10) {
                Button(action: onClose) {
                    Text("Close")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }

                if isEquipped {
                    Button(action: onUpgrade) {
                        Text("Upgrade  ·  \(item.upgradeCost) mesos")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(canAffordUpgrade
                                             ? Color(red: 0.02, green: 0.13, blue: 0.06)
                                             : .white.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(canAffordUpgrade
                                        ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.91, blue: 0.53),
                                                                                Color(red: 0.25, green: 0.82, blue: 0.49)],
                                                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(.white.opacity(0.08)),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canAffordUpgrade)
                    .frame(maxWidth: .infinity)
                } else {
                    Button(action: onEquip) {
                        Text(canWear ? "Equip" : "Requires Lv \(item.requiredLevel)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(canWear
                                             ? Color(red: 0.02, green: 0.13, blue: 0.06)
                                             : .white.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(canWear
                                        ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.49, green: 0.91, blue: 0.53),
                                                                                Color(red: 0.25, green: 0.82, blue: 0.49)],
                                                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                                        : AnyShapeStyle(.white.opacity(0.08)),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canWear)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
    }
}

