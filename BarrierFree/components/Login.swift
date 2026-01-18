//
//  Untitled.swift
//  BarrierFree
//
//  Created by TA616 on 17.01.26.
//

import SwiftUI // Import aus einer Bibliothek

struct Login: View {
    @State private var email = ""
    @State private var password = "" // @state ist dafür da den wert zu speichern
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Anmelden")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.green)
                    .offset(y: -70)
                
                // E-Mail Eingabe (Tastatur kommt automatisch)
                TextField("E-mail", text: $email)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                
                // Passwort Eingabe SecureField=passwort zensiert
                SecureField("Password", text: $password)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .textContentType(.password)
                
                Button("Login") {
                
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .offset(y: -80)
            
            Spacer()
            Spacer()
            Spacer()
        }
        .padding()
        .background(Color(red: 74/255, green: 79/255, blue: 83/255))
    }
}

#Preview {
    Login()
}
