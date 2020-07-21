//
//  SolutionViews.swift
//  MorphicManualTester
//
//  Created by CatalinaTest on 7/20/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import SwiftUI

struct SolutionSection: View {
    @ObservedObject var solution: SolutionCollection
    @State var active: Bool = false
    var body: some View {
        VStack(spacing: 0.0) {
            HStack {
                if(active)
                {
                    Text("COLLAPSE")
                }
                else
                {
                    Text("EXPAND")
                }
                Text(solution.id)
                    .font(.headline)
                Spacer()
            }
            .padding(.all)
            Section {
                ForEach(solution.settings.sorted()) {setting in
                    Divider()
                    if(setting.type == SettingType.boolean) {
                        BooleanEntry(setting: setting)
                    }
                    else if(setting.type == SettingType.double) {
                        Text("THIS IS BROKEN")
                    }
                    else if(setting.type == SettingType.integer) {
                        Text("THIS IS BROKEN")
                    }
                    else if(setting.type == SettingType.string) {
                        Text("THIS IS BROKEN")
                    }
                }
            }
        }
    }
}

struct BooleanEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.id)
                .font(.body)
                
            Spacer()
            Text("Boolean:")
            Toggle("", isOn: $setting.val_bool)
        }
        .padding(.leading, 30.0)
        .padding(/*@START_MENU_TOKEN@*/[.top, .bottom, .trailing], 5.0/*@END_MENU_TOKEN@*/)
    }
}

struct TestRow: View {
    var body: some View {
        HStack {
            Text("AYY LMAO")
            Spacer()
            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Text("Button")
            }
        }
    }
}

struct SolutionViews_Previews: PreviewProvider {
    static var previews: some View {
        let solution = SolutionCollection(solutionName: "morphic.solution.name")
        solution.settings.append(SettingControl(name: "FIRST SETTING", solname: "solution", type: SettingType.boolean))
        solution.settings.append(SettingControl(name: "SECOND SETTING", solname: "solution", type: SettingType.boolean))
        solution.settings.append(SettingControl(name: "THIRD SETTING", solname: "solution", type: SettingType.boolean))
        solution.settings.append(SettingControl(name: "FOURTH SETTING", solname: "solution", type: SettingType.boolean))
        return SolutionSection(solution: solution)
    }
}
