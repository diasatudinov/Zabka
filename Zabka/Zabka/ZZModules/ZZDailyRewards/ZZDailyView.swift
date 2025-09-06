//
//  ZZDailyView.swift
//  Zabka
//
//

import SwiftUI

struct ZZDailyView: View {
    @Environment(\.presentationMode) var presentationMode
        @StateObject private var viewModel = DailyRewardsViewModel()
        
        private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        private let dayCellHeight: CGFloat = CPDeviceManager.shared.deviceType == .pad ? 200:108
        var body: some View {
            ZStack {
                VStack(spacing: 0) {
                    
                    ZStack {
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(1...viewModel.totalDaysCount, id: \.self) { day in
                                ZStack {
                                    Image(.dayBgZZ)
                                        .resizable()
                                        .scaledToFit()
                                        
                                    VStack(spacing: 5) {
                                        Spacer()
                                        Text("Day \(day)")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(.white)
                                            .textCase(.uppercase)
                                        
                                    }.padding(5)
                                }
                                .frame(width: 105, height: dayCellHeight)
                                .offset(x: day > 4 ? dayCellHeight/2:0)
                                .opacity(viewModel.isDayClaimed(day) ? 1: viewModel.isDayUnlocked(day) ? 0.7:0.3)
                                .onTapGesture {
                                    viewModel.claimNext()
                                }
                                
                            }
                        }.frame(width: CPDeviceManager.shared.deviceType == .pad ? 800:450)
                    }
                }.padding()
                
                VStack {
                    HStack(alignment: .top) {
                        CPCoinBg()
                        
                        Spacer()
                    }.padding([.horizontal, .top])
                    
                    Spacer()
                    
                    HStack(alignment: .top) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconZZ)
                                .resizable()
                                .scaledToFit()
                                .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:50)
                        }
                        Spacer()
                    }.padding([.horizontal, .top])
                }
                
            }.background(
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
    ZZDailyView()
}
