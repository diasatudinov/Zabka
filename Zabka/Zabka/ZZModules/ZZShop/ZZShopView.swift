//
//  ZZShopView.swift
//  Zabka
//
//

import SwiftUI

struct ZZShopView: View {
    @StateObject var user = CPUser.shared
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CPShopViewModel
    @State var category: JGItemCategory = .background
    var body: some View {
        ZStack {
             
            VStack {
                
                Image(.shopTextZZ)
                    .resizable()
                    .scaledToFit()
                    .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:50)
                HStack {
                    
                    Image(.arrowLeftZZ)
                        .resizable()
                        .scaledToFit()
                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:60)
                    
                    ForEach(viewModel.shopBgItems, id: \.self) { item in
                        achievementItem(item: item, category: .background)
                        
                    }
                    
                    Image(.arrowLeftZZ)
                        .resizable()
                        .scaledToFit()
                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:60)
                        .scaleEffect(x: -1, y: 1)
                }
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
    
    @ViewBuilder func achievementItem(item: JGItem, category: JGItemCategory) -> some View {
        ZStack {
            
            Image(item.icon)
                .resizable()
                .scaledToFit()
            VStack {
                Spacer()
            Button {
                viewModel.selectOrBuy(item, user: user, category: category)
            } label: {
                
                if viewModel.isPurchased(item, category: category) {
                    ZStack {
                        Image(.btnBgZZ)
                            .resizable()
                            .scaledToFit()
                        Text(viewModel.isCurrentItem(item: item, category: category) ? "USED": "USE")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                        
                        
                    }.frame(height: CPDeviceManager.shared.deviceType == .pad ? 50:25)
                    
                } else {
                    Image(.twentyCoinZZ)
                        .resizable()
                        .scaledToFit()
                        .frame(height: CPDeviceManager.shared.deviceType == .pad ? 50:25)
                        .opacity(viewModel.isMoneyEnough(item: item, user: user, category: category) ? 1:0.6)
                }
                
                
            }
            }.padding(10)
            
        }.frame(height: CPDeviceManager.shared.deviceType == .pad ? 300:130)
        
    }
}

#Preview {
    ZZShopView(viewModel: CPShopViewModel())
}
