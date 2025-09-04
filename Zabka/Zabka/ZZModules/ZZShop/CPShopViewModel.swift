import SwiftUI


final class CPShopViewModel: ObservableObject {
    // MARK: – Shop catalogues
    @Published var shopBgItems: [JGItem] = [
        JGItem(name: "bg1", image: "bgImage1CP", icon: "gameBgIcon1CP", text: "gameBgText1CP", price: 100),
        JGItem(name: "bg2", image: "bgImage2CP", icon: "gameBgIcon2CP", text: "gameBgText2CP", price: 100),
        JGItem(name: "bg3", image: "bgImage3CP", icon: "gameBgIcon3CP", text: "gameBgText3CP", price: 100),
        JGItem(name: "bg4", image: "bgImage4CP", icon: "gameBgIcon4CP", text: "gameBgText4CP", price: 100),

    ]
    
    @Published var shopSkinItems: [JGItem] = [
        JGItem(name: "skin1", image: "skinImage1CP", icon: "skinIcon1CP", text: "skinText1CP", price: 100),
        JGItem(name: "skin2", image: "skinImage2CP", icon: "skinIcon2CP", text: "skinText2CP", price: 100),
        JGItem(name: "skin3", image: "skinImage3CP", icon: "skinIcon3CP", text: "skinText3CP", price: 100),
        JGItem(name: "skin4", image: "skinImage4CP", icon: "skinIcon4CP", text: "skinText4CP", price: 100),

    ]
    
    // MARK: – Bought
    @Published var boughtBgItems: [JGItem] = [
        JGItem(name: "bg1", image: "bgImage1CP", icon: "gameBgIcon1CP", text: "gameBgText1CP", price: 100),
    ] {
        didSet { saveBoughtBg() }
    }

    @Published var boughtSkinItems: [JGItem] = [
        JGItem(name: "skin1", image: "skinImage1CP", icon: "skinIcon1CP", text: "skinText1CP", price: 100),
    ] {
        didSet { saveBoughtSkins() }
    }
    
    // MARK: – Current selections
    @Published var currentBgItem: JGItem? {
        didSet { saveCurrentBg() }
    }
    @Published var currentSkinItem: JGItem? {
        didSet { saveCurrentSkin() }
    }
    
    // MARK: – UserDefaults keys
    private let bgKey            = "currentBgJG1"
    private let boughtBgKey      = "boughtBgJG1"
    private let skinKey          = "currentSkinJG1"
    private let boughtSkinKey    = "boughtSkinJG1"
    
    // MARK: – Init
    init() {
        loadCurrentBg()
        loadBoughtBg()
                
        loadCurrentSkin()
        loadBoughtSkins()
    }
    
    // MARK: – Save / Load Backgrounds
    private func saveCurrentBg() {
        guard let item = currentBgItem,
              let data = try? JSONEncoder().encode(item)
        else { return }
        UserDefaults.standard.set(data, forKey: bgKey)
    }
    private func loadCurrentBg() {
        if let data = UserDefaults.standard.data(forKey: bgKey),
           let item = try? JSONDecoder().decode(JGItem.self, from: data) {
            currentBgItem = item
        } else {
            currentBgItem = shopBgItems.first
        }
    }
    private func saveBoughtBg() {
        guard let data = try? JSONEncoder().encode(boughtBgItems) else { return }
        UserDefaults.standard.set(data, forKey: boughtBgKey)
    }
    private func loadBoughtBg() {
        if let data = UserDefaults.standard.data(forKey: boughtBgKey),
           let items = try? JSONDecoder().decode([JGItem].self, from: data) {
            boughtBgItems = items
        }
    }
    
    // MARK: – Save / Load Skins
    private func saveCurrentSkin() {
        guard let item = currentSkinItem,
              let data = try? JSONEncoder().encode(item)
        else { return }
        UserDefaults.standard.set(data, forKey: skinKey)
    }
    private func loadCurrentSkin() {
        if let data = UserDefaults.standard.data(forKey: skinKey),
           let item = try? JSONDecoder().decode(JGItem.self, from: data) {
            currentSkinItem = item
        } else {
            currentSkinItem = shopSkinItems.first
        }
    }
    private func saveBoughtSkins() {
        guard let data = try? JSONEncoder().encode(boughtSkinItems) else { return }
        UserDefaults.standard.set(data, forKey: boughtSkinKey)
    }
    private func loadBoughtSkins() {
        if let data = UserDefaults.standard.data(forKey: boughtSkinKey),
           let items = try? JSONDecoder().decode([JGItem].self, from: data) {
            boughtSkinItems = items
        }
    }
    
    // MARK: – Example buy action
    func buy(_ item: JGItem, category: JGItemCategory) {
        switch category {
        case .background:
            guard !boughtBgItems.contains(item) else { return }
            boughtBgItems.append(item)
        case .skin:
            guard !boughtSkinItems.contains(item) else { return }
            boughtSkinItems.append(item)
        }
    }
    
    func isPurchased(_ item: JGItem, category: JGItemCategory) -> Bool {
        switch category {
        case .background:
            return boughtBgItems.contains(where: { $0.name == item.name })
        case .skin:
            return boughtSkinItems.contains(where: { $0.name == item.name })
        }
    }

    func selectOrBuy(_ item: JGItem, user: CPUser, category: JGItemCategory) {
        
        switch category {
        case .background:
            if isPurchased(item, category: .background) {
                currentBgItem = item
            } else {
                guard user.money >= item.price else {
                    return
                }
                user.minusUserMoney(for: item.price)
                buy(item, category: .background)
            }
        case .skin:
            if isPurchased(item, category: .skin) {
                currentSkinItem = item
            } else {
                guard user.money >= item.price else {
                    return
                }
                user.minusUserMoney(for: item.price)
                buy(item, category: .skin)
            }
        }
    }
    
    func isMoneyEnough(item: JGItem, user: CPUser, category: JGItemCategory) -> Bool {
        user.money >= item.price
    }
    
    func isCurrentItem(item: JGItem, category: JGItemCategory) -> Bool {
        switch category {
        case .background:
            guard let currentItem = currentBgItem, currentItem.name == item.name else {
                return false
            }
            
            return true
            
        case .skin:
            guard let currentItem = currentSkinItem, currentItem.name == item.name else {
                return false
            }
            
            return true
        }
    }
    
    func nextCategory(category: JGItemCategory) -> JGItemCategory {
        if category == .skin {
            return .background
        } else {
            return .skin
        }
    }
}

enum JGItemCategory: String {
    case background = "background"
    case skin = "skin"
}

struct JGItem: Codable, Hashable {
    var id = UUID()
    var name: String
    var image: String
    var icon: String
    var text: String
    var price: Int
}