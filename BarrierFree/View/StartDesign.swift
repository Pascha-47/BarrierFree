//
//  StartDesign.swift
//  BarrierFree
//
//  Created by TA601 on 18.01.26.
//
import SwiftUI

struct StartDesign: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image("BarrierFreeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 270, height: 270)
                .cornerRadius(20)

            Text("BarrierFree")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.green)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 74/255, green: 79/255, blue: 83/255))
    }
}

struct StartView: View {
    @State private var showLogin = false
    
    var body: some View {
        ZStack {
            StartDesign()
                .onAppear {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showLogin = true
                    }
                }
            
            
            .fullScreenCover(isPresented: $showLogin) {
                NavigationStack {  
                    Login()
                }
            }
        }
    }
}

#Preview {
    StartView()
}
