//
//  ContentView.swift
//  MorphicManualTester
//
//  Created by James Vanderheiden on 7/15/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import SwiftUI

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
                    Toggle(isOn: $manager.autoApply) {
                        Text("Auto Apply")
                            .padding([.top, .bottom, .trailing])
                        
                    }
                    .padding(.vertical)
                    Button(action: registry.CaptureAllSettings) {
                        Text("Refresh")
                    }
                    .padding(.vertical)
                    Button(action: registry.ApplyAllSettings) {
                        Text("Apply Settings")
                    }
                    .padding(.vertical)
                    Button(action: registry.LoadSolution) {
                        Text("Load New Registry")
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
            .background(/*@START_MENU_TOKEN@*/Color(hue: 0.307, saturation: 0.976, brightness: 0.418)/*@END_MENU_TOKEN@*/)
            ScrollView() {
                ForEach(registry.solutions) { solution in
                    SolutionSection(solution: solution)
                }
            }
        }
        .frame(width: 800.0, height: 800.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
