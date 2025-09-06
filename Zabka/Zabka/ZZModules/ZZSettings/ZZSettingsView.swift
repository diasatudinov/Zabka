//
//  ZZSettingsView.swift
//  Zabka
//
//

import SwiftUI

struct ZZSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
        @StateObject var settingsVM = CPSettingsViewModel()
        var body: some View {
            ZStack {
                
                VStack {
                    
                    ZStack {
                        
                        Image(.settingsBgZZ)
                            .resizable()
                            .scaledToFit()
                        
                        
                        VStack(spacing: 20) {
                            
                            HStack {
                                
                                Image(.effectsTextZZ)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: CPDeviceManager.shared.deviceType == .pad ? 80:30)
                                
                                Button {
                                    withAnimation {
                                        settingsVM.effectsEnabled.toggle()
                                    }
                                } label: {
                                    Image(settingsVM.effectsEnabled ? .onZZ:.ofZZ)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 80:30)
                                }
                            }
                            
                            HStack {
                                
                                Image(.musicTextZZ)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: CPDeviceManager.shared.deviceType == .pad ? 80:30)
                                
                                Button {
                                    withAnimation {
                                        settingsVM.soundEnabled.toggle()
                                    }
                                } label: {
                                    Image(settingsVM.soundEnabled ? .onZZ:.ofZZ)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 80:30)
                                }
                            }
                           
                        }.padding(.bottom, 32)
                    }.frame(height: CPDeviceManager.shared.deviceType == .pad ? 88:300)
                    
                }
                
                VStack {
                    HStack {
                       
                        CPCoinBg()
                        
                        Spacer()
                        
                    }.padding()
                    Spacer()
                    
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconZZ)
                                .resizable()
                                .scaledToFit()
                                .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:50)
                        }
                        
                        Spacer()
                        
                        
                    }.padding()
                    
                }
            }.frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        Image(.appBgZZ)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        
                    }
                )
        }
    }

#Preview {
    ZZSettingsView()
}
