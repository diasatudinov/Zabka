//
//  CPCoinBg.swift
//  Zabka
//
//


import SwiftUI

struct CPCoinBg: View {
    @StateObject var user = CPUser.shared
    var height: CGFloat = CPDeviceManager.shared.deviceType == .pad ? 100:50
    var body: some View {
        ZStack {
            Image(.coinsBgZZ)
                .resizable()
                .scaledToFit()
            
            Text("\(user.money)")
                .font(.system(size: CPDeviceManager.shared.deviceType == .pad ? 45:25, weight: .black))
                .foregroundStyle(.white)
                .textCase(.uppercase)
                .offset(x: 15)
            
            
            
        }.frame(height: height)
        
    }
}

#Preview {
    CPCoinBg()
}
