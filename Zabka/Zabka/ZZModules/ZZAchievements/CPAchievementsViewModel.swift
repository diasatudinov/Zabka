//
//  CPAchievementsViewModel.swift
//  Zabka
//
//


import SwiftUI

class CPAchievementsViewModel: ObservableObject {
    
    @Published var achievements: [NEGAchievement] = [
        NEGAchievement(image: "achieve1ImageCP", title: "achieve1TextCP", isAchieved: false),
        NEGAchievement(image: "achieve2ImageCP", title: "achieve2TextCP", isAchieved: false),
        NEGAchievement(image: "achieve3ImageCP", title: "achieve3TextCP", isAchieved: false),
        NEGAchievement(image: "achieve4ImageCP", title: "achieve4TextCP", isAchieved: false),

    ] {
        didSet {
            saveAchievementsItem()
        }
    }
    
    @Published var dailyQuests: [NEGAchievement] = [
        NEGAchievement(image: "", title: "quest1TextCP", isAchieved: false),
        NEGAchievement(image: "", title: "quest2TextCP", isAchieved: false),
        NEGAchievement(image: "", title: "quest3TextCP", isAchieved: false)
    ] {
        didSet {
            saveDailyQuestsItem()
        }
    }
    
    init() {
        loadAchievementsItem()
        
    }
    
    private let userDefaultsAchievementsKey = "achievementsKeyCP"
    private let userDefaultsDailyQuestsKey = "questsKeyCP"
    
    func achieveToggle(_ achive: NEGAchievement) {
        guard let index = achievements.firstIndex(where: { $0.id == achive.id })
        else {
            return
        }
        achievements[index].isAchieved.toggle()
        
    }
    
    func questsToggle(_ achive: NEGAchievement) {
        guard let index = dailyQuests.firstIndex(where: { $0.id == achive.id })
        else {
            return
        }
        dailyQuests[index].isAchieved.toggle()
        
    }
    
    
    func saveAchievementsItem() {
        if let encodedData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsAchievementsKey)
        }
        
    }
    
    func loadAchievementsItem() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsAchievementsKey),
           let loadedItem = try? JSONDecoder().decode([NEGAchievement].self, from: savedData) {
            achievements = loadedItem
        } else {
            print("No saved data found")
        }
    }
    
    func saveDailyQuestsItem() {
        if let encodedData = try? JSONEncoder().encode(dailyQuests) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsDailyQuestsKey)
        }
        
    }
    
    func loadDailyQuestsItem() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsDailyQuestsKey),
           let loadedItem = try? JSONDecoder().decode([NEGAchievement].self, from: savedData) {
            dailyQuests = loadedItem
        } else {
            print("No saved data found")
        }
    }
}

struct NEGAchievement: Codable, Hashable, Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var isAchieved: Bool
}
