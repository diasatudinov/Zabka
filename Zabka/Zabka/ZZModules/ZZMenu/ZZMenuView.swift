//
//  ZZMenuView.swift
//  Zabka
//
//

import SwiftUI

struct ZZMenuView: View {
    @State private var showGame = false
    @State private var showShop = false
    @State private var showAchievement = false
    @State private var showMiniGames = false
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showDailyReward = false
    
    @StateObject var shopVM = CPShopViewModel()
    
    var body: some View {
        
        ZStack {
            
            
            VStack(spacing: 0) {
                
                HStack {
                    CPCoinBg()
                    
                    Spacer()
                }.padding(20)
                Spacer()
                
                HStack(alignment: .bottom, spacing: 7) {
                    
                    VStack(spacing: 20) {
                        
                        Image(.menuLogoZZ)
                            .resizable()
                            .scaledToFit()
                            .frame(height: CPDeviceManager.shared.deviceType == .pad ? 140:70)
                        
                        VStack {
                            HStack {
                                
                                Button {
                                    showGame = true
                                } label: {
                                    Image(.playIconZZ)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 140:75)
                                }
                                
                                Button {
                                    showShop = true
                                } label: {
                                    Image(.shopIconZZ)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 140:75)
                                }
                            }
                            
                            HStack {
                                Button {
                                    showAchievement = true
                                } label: {
                                    Image(.achievementsIconZZ)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 140:75)
                                }
                                
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(.settingsIconZZ)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:75)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    Button {
                        withAnimation {
                            showDailyReward = true
                        }
                    } label: {
                        Image(.dailyIconZZ)
                            .resizable()
                            .scaledToFit()
                            .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:120)
                    }
                }
                Spacer()
            }
            
            
            
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    Image(.menuBgZZ)
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFill()
                }
            )
            .fullScreenCover(isPresented: $showGame) {
               // CPLevelSelectView()
            }
            .fullScreenCover(isPresented: $showAchievement) {
                ZZAchievementsView()
            }
            .fullScreenCover(isPresented: $showShop) {
                ZZShopView(viewModel: shopVM)
            }
            .fullScreenCover(isPresented: $showSettings) {
                ZZSettingsView()
            }
            .fullScreenCover(isPresented: $showDailyReward) {
                ZZDailyView()
            }
    }
}


#Preview {
    ZZMenuView()
}
