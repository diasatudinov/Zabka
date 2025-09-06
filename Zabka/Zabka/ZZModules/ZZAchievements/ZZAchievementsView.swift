//
//  ZZAchievementsView.swift
//  Zabka
//
//

import SwiftUI

struct ZZAchievementsView: View {
       @StateObject var user = CPUser.shared
       @Environment(\.presentationMode) var presentationMode
       
       @StateObject var viewModel = CPAchievementsViewModel()
       @State private var index = 0
       var body: some View {
           ZStack {
              
               VStack {
                   ZStack {
                       HStack(alignment: .top) {
                           
                           CPCoinBg()
                           
                           Spacer()
                       }
                   }.padding([.top])
                   Spacer()
                   HStack(spacing: 20) {
                       Image(.arrowLeftZZ)
                           .resizable()
                           .scaledToFit()
                           .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:60)
                       ForEach(viewModel.achievements, id: \.self) { item in
                           Image(item.image)
                               .resizable()
                               .scaledToFit()
                               .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:120)
                               .opacity(item.isAchieved ? 1:0.5)
                               .onTapGesture {
                                   viewModel.achieveToggle(item)
                                   if !item.isAchieved {
                                       user.updateUserMoney(for: 10)
                                   }
                               }
                       }
                       Image(.arrowLeftZZ)
                           .resizable()
                           .scaledToFit()
                           .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:60)
                           .scaleEffect(x: -1, y: 1)
                   }
                      
                   Spacer()
                   
                   HStack(alignment: .top) {
                       
                       Button {
                           presentationMode.wrappedValue.dismiss()
                           
                       } label: {
                           Image(.backIconZZ)
                               .resizable()
                               .scaledToFit()
                               .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:60)
                       }
                       
                       Spacer()
                   }
               }
           }
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
    ZZAchievementsView()
}
