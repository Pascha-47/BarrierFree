//
//  StartDesign.swift
//  BarrierFree
//
//  Created by TA601 on 18.01.26.
//
import SwiftUI
import MapKit

struct StartDesign: View {
    var body: some View {
        VStack(spacing: 16) {
        
            Spacer()
            Image("BarrierFreeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 270, height: 270  )
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

#Preview {
    StartDesign()
}
