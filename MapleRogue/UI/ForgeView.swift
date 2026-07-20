import SwiftUI

/// The Forge tab: two enhancement paths on your equipped gear.
/// Starforce — stars on any equipped item (weapon stars = ATK, armor
/// stars = HP), destroy risk. Cubes — reroll potential lines with pity.
struct ForgeView: View {

    private enum Mode: String, CaseIterable {
        case starforce = "Starforce"
        case cube = "Cubes"
    }

    @ObservedObject var profileVM: ProfileViewModel

    @State private var mode: Mode = .starforce
    @State private var selectedSlot: GearSlot = .weapon
    @State private var lastOutcome: StarforceOutcome?
    @State private var isRolling = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 18) {
            header

            if !profileVM.isUnlocked(.forge) {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Forge unlocks at Lv 3")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Keep running Henesys Ruins to level up")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))

                    #if DEBUG
                    Button {
                        profileVM.debugBoost()
                    } label: {
                        Text("DEV: +3000 XP, +5000 mesos")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.orange, in: Capsule())
                    }
                    .padding(.top, 8)
                    #endif
                }
                .padding(.vertical, 50)
            } else {
                modePicker

                switch mode {
                case .starforce:
                    slotPicker
                    if let item = profileVM.equippedItem(in: selectedSlot) {
                        itemCard(item)
                        oddsPanel(item)
                        outcomeBanner
                        enhanceButton(item)
                    } else if selectedSlot == .weapon {
                        noWeaponPanel
                    } else {
                        Text("Nothing equipped in this slot")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.vertical, 30)
                    }
                case .cube:
                    CubeSection(profileVM: profileVM)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Forge")
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 5) {
                Circle().fill(.yellow).frame(width: 12, height: 12)
                Text("\(profileVM.profile.mesos) mesos")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(Mode.allCases, id: \.self) { candidate in
                Button {
                    mode = candidate
                } label: {
                    Text(candidate.rawValue)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(mode == candidate ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(mode == candidate ? AnyShapeStyle(.yellow) : AnyShapeStyle(.white.opacity(0.08)),
                                    in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Slot picker

    private var slotPicker: some View {
        HStack(spacing: 8) {
            ForEach(GearSlot.allCases, id: \.self) { slot in
                let item = profileVM.equippedItem(in: slot)
                Button {
                    selectedSlot = slot
                    lastOutcome = nil
                } label: {
                    EquipSlotView(label: slot.rawValue,
                                  rarity: item?.rarity,
                                  level: item?.level,
                                  size: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedSlot == slot ? .yellow : .clear, lineWidth: 2))
                }
            }
        }
    }

    // MARK: - Item card

    private func itemCard(_ weapon: GearItem) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .frame(height: 48)

            Text(weapon.name)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            starRow(weapon)

            Text(weapon.slot == .weapon
                 ? "+\(weapon.starforceAtkPercent)% ATK from stars  ·  \(weapon.rarity.displayName) Lv \(weapon.level)"
                 : "+\(weapon.starforceBonusHP) HP from stars  ·  \(weapon.rarity.displayName) Lv \(weapon.level)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(weapon.slot == .weapon ? .orange : .green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderColor, lineWidth: 2))
        .offset(x: shakeOffset)
    }

    private func starRow(_ weapon: GearItem) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<GearItem.maxStars, id: \.self) { index in
                Image(systemName: index < weapon.stars ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundStyle(index < weapon.stars ? .yellow : .white.opacity(0.25))
            }
        }
    }

    private var borderColor: Color {
        switch lastOutcome {
        case .success: .green
        case .fail: .orange
        case .destroyed: .red
        case nil: .white.opacity(0.1)
        }
    }

    // MARK: - Odds disclosure

    private func oddsPanel(_ weapon: GearItem) -> some View {
        let odds = StarforceTable.odds(forStar: weapon.stars)
        return HStack(spacing: 18) {
            oddsColumn("Success", value: odds.success, color: .green)
            oddsColumn("Fail", value: odds.fail, color: .orange)
            oddsColumn("DESTROY", value: odds.destroy, color: .red)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 22)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private func oddsColumn(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(String(format: "%.1f%%", value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Outcome + actions

    @ViewBuilder
    private var outcomeBanner: some View {
        switch lastOutcome {
        case .success(let stars):
            Text("SUCCESS! ★\(stars)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.green)
        case .fail:
            Text("Failed. Mesos consumed.")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
        case .destroyed, nil:
            EmptyView()
        }
    }

    private func enhanceButton(_ weapon: GearItem) -> some View {
        let cost = profileVM.enhanceCost(for: weapon)
        let affordable = cost.map { profileVM.profile.mesos >= $0 } ?? false

        return Button {
            roll(weapon)
        } label: {
            Text(cost.map { "ENHANCE  (\($0) mesos)" } ?? "MAX STARS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(affordable ? .black : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(affordable ? AnyShapeStyle(.yellow) : AnyShapeStyle(.white.opacity(0.1)),
                            in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!affordable || isRolling)
    }

    private var noWeaponPanel: some View {
        VStack(spacing: 14) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 44))
                .foregroundStyle(.red)
            Text("No Weapon Equipped")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Equip a weapon in the Character tab, or buy a basic one. If the stars claimed your blade — that is the way of starforce.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                profileVM.buyReplacementWeapon()
                lastOutcome = nil
            } label: {
                Text("Buy Training Sword  (\(profileVM.replacementWeaponCost) mesos)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(profileVM.profile.mesos >= profileVM.replacementWeaponCost
                                     ? .black : .white.opacity(0.4))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(profileVM.profile.mesos >= profileVM.replacementWeaponCost
                                ? AnyShapeStyle(.yellow) : AnyShapeStyle(.white.opacity(0.1)),
                                in: Capsule())
            }
            .disabled(profileVM.profile.mesos < profileVM.replacementWeaponCost)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.red.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Roll with suspense

    private func roll(_ item: GearItem) {
        guard !isRolling else { return }
        isRolling = true
        lastOutcome = nil

        // Brief anticipation shake before the reveal.
        withAnimation(.easeInOut(duration: 0.08).repeatCount(7, autoreverses: true)) {
            shakeOffset = 5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            shakeOffset = 0
            withAnimation(.bouncy) {
                lastOutcome = profileVM.attemptStarforce(on: item.id)
            }
            isRolling = false
        }
    }
}
