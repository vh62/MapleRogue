import SwiftUI

/// Shared Forge selection: slot filter row + every OWNED item in that slot
/// (equipped or not). Enhancing shouldn't require equipping first.
struct ForgeItemPicker: View {

    @ObservedObject var profileVM: ProfileViewModel
    @Binding var selectedSlot: GearSlot
    @Binding var selectedItemID: UUID?

    private var ownedInSlot: [GearItem] {
        profileVM.profile.gearInventory.filter { $0.slot == selectedSlot }
    }

    private var equippedID: UUID? {
        profileVM.activePreset.itemID(for: selectedSlot)
    }

    var body: some View {
        VStack(spacing: 10) {
            // Slot filter
            HStack(spacing: 8) {
                ForEach(GearSlot.allCases, id: \.self) { slot in
                    let equipped = profileVM.equippedItem(in: slot)
                    Button {
                        selectedSlot = slot
                        selectedItemID = nil
                        repairSelection()
                    } label: {
                        EquipSlotView(label: slot.rawValue,
                                      rarity: equipped?.rarity,
                                      level: equipped?.level,
                                      size: 44)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedSlot == slot ? .yellow : .clear, lineWidth: 2))
                    }
                }
            }

            // All owned items in the slot
            if !ownedInSlot.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ownedInSlot) { item in
                            Button {
                                selectedItemID = item.id
                            } label: {
                                EquipSlotView(label: item.slot.rawValue,
                                              rarity: item.rarity,
                                              level: item.level,
                                              size: 48)
                                    .overlay(RoundedRectangle(cornerRadius: 13)
                                        .stroke(selectedItemID == item.id ? .cyan : .white.opacity(0.1),
                                                lineWidth: 2))
                                    .overlay(alignment: .topLeading) {
                                        if item.id == equippedID {
                                            Text("E")
                                                .font(.system(size: 8, weight: .black, design: .rounded))
                                                .foregroundStyle(.black)
                                                .padding(3)
                                                .background(.cyan, in: Circle())
                                                .offset(x: -4, y: -4)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
            }
        }
        .onAppear { repairSelection() }
        .onChange(of: profileVM.profile.gearInventory) { repairSelection() }
    }

    /// Keeps the selection valid: prefer the current pick, else the
    /// equipped item, else the first owned item in the slot.
    private func repairSelection() {
        let owned = ownedInSlot
        if let id = selectedItemID, owned.contains(where: { $0.id == id }) { return }
        selectedItemID = equippedID.flatMap { id in owned.first { $0.id == id }?.id }
            ?? owned.first?.id
    }
}
