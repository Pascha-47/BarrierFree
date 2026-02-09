//
//  RegistrierView.swift
//  BarrierFree
//
//  Created by TA616 on 18.01.26.
//

import SwiftUI

struct RegistrierView: View {
    @State private var vorname = ""
    @State private var nachname = ""
    @State private var benutzername = ""
    @State private var passwort = ""
    @State private var passwortWiederholung = ""
    @State private var selectedEinschraenkung: String = "Wähle Einschränkung"
    
    let einschraenkungen = ["Rollstuhl", "Autismus", "Keine angabe", ]
    
    var body: some View {
        ZStack {
            Color(red: 74/255, green: 79/255, blue: 83/255)
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                Text("Registrieren")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.green)
                
                TextField("Vorname", text: $vorname)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .padding(10)
                
                TextField("Nachname", text: $nachname)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .padding(10)
                
                TextField("Benutzername", text: $benutzername)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .padding(10)
                
                TextField("Passwort", text: $passwort)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .padding(10)
                
                TextField("Passwort wiederholen", text: $passwortWiederholung)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundStyle(Color.green)
                    .cornerRadius(10)
                    .padding(10)
                
                
                HStack {
                    Text(selectedEinschraenkung)
                        .foregroundStyle(Color.green)  // Gleicher grüner Stil
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    Menu {
                        ForEach(einschraenkungen, id: \.self) { option in
                            Button(option) {
                                selectedEinschraenkung = option
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Color.green)
                            .font(.title2)
                            .padding(.trailing)
                    }
                }
                .contentShape(Rectangle())
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(10)
                .padding(10)
                
                HStack(spacing: 20) {
                    Spacer()
                    
                    Button("Weiter") { }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
}

#Preview {
    RegistrierView()
}
