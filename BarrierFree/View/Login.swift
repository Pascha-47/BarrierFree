//
//  Untitled.swift
//  BarrierFree
//
//  Created by TA616 on 17.01.26.
//

import SwiftUI
import MapKit

struct Login: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showMap = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 74/255, green: 79/255, blue: 83/255)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Anmelden")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                            .offset(y: -70)
                        
                        TextField("E-mail", text: $email)
                            .textFieldStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .foregroundStyle(.green)
                            .cornerRadius(10)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .foregroundStyle(.green)
                            .cornerRadius(10)
                            .textContentType(.password)
                        
                        HStack {
                            NavigationLink(destination: RegistrierView()) {
                                Text("Registrieren")
                            }
                            
                            Button("Login") {
                                showMap = true
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(email.isEmpty || password.isEmpty ? .gray : .green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .disabled(email.isEmpty || password.isEmpty)
                        }
                    }
                    .offset(y: -80)
                    
                    Button("Überspringen") {
                        showMap = true
                    }
                    .foregroundStyle(.blue)
                    .font(.callout)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showMap) {  // <- AUF ZStack-Ebene!
                MapView()
            }
        }
    }
}

#Preview {
    Login()
}
