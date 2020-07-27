//
//  ContentView.swift
//  MorphicManualTester
//
//  Created by James Vanderheiden on 7/15/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import SwiftUI

let color_bg = Color(hue: 0.307, saturation: 0.976, brightness: 0.418)

struct ContentView: View {
    @ObservedObject var manager: RegistryManager = registry
    var body: some View {
        VStack(spacing: 0.0) {
            VStack() {
                HStack(alignment: .center) {
                    Text("Manual Settings Tester")
                        .font(.headline)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.leading)
                        .padding()
                    Spacer()
                    Button(action: registry.LoadSolution) {
                        Text("Load a Different Registry")
                    }
                    .padding([.top, .bottom, .trailing])
                }
                .padding(.vertical, 0.0)
                .frame(height: 40.0)
                HStack() {
                    Text(registry.load)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.bottom, 10.0)
                
            }
            .background(color_bg)
            ScrollView() {
                ForEach(registry.solutions) { solution in
                    SolutionSection(solution: solution)
                }
            }
            HStack() {
                Spacer()
                Toggle(isOn: $manager.autoApply) {
                    Text("Auto Apply")
                }.toggleStyle(SwitchToggleStyle())
                .padding(.vertical)
                HStack {
                    if(!manager.autoApply) {
                        Button(action: registry.ApplyAllSettings) {
                            Text("Apply Settings")
                        }
                    }
                    else {
                        Button(action: {}) {
                            Text("Apply Settings")
                        }.hidden()
                    }
                }
                .padding(.horizontal)
            }
            .background(color_bg)
        }
        .frame(width: 800.0, height: 800.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
