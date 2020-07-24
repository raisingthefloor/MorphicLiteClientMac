//
//  SolutionViews.swift
//  MorphicManualTester
//
//  Created by CatalinaTest on 7/20/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import SwiftUI
import MorphicSettings

struct SolutionSection: View {
    @ObservedObject var solution: SolutionCollection
    @State var active: Bool = false
    var body: some View {
        VStack(spacing: 0.0) {
            HStack {
                if(active)
                {
                    Text("\u{25bc}")
                        .font(.headline)
                }
                else
                {
                    Text("\u{25b6}")
                        .font(.headline)
                }
                Text(solution.name)
                    .font(.headline)
                Spacer()
            }
            .onTapGesture {
                self.active = !self.active
            }
            .padding(.all)
            Section() {
                ForEach(solution.settings) {setting in
                    if(self.active) {
                        Divider()
                        if(setting.type == Setting.ValueType.boolean) {
                            BooleanEntry(setting: setting)
                        }
                        else if(setting.type == Setting.ValueType.double) {
                            DoubleEntry(setting: setting)
                        }
                        else if(setting.type == Setting.ValueType.integer) {
                            IntegerEntry(setting: setting)
                        }
                        else if(setting.type == Setting.ValueType.string) {
                            StringEntry(setting: setting)
                        }
                    }
                }
            }
            Divider()
        }
    }
    func toggleDrop() {
        self.active = !self.active
    }
}

struct BooleanEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            Text("Boolean:")
            Toggle("", isOn: $setting.displayBool)
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct IntegerEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            Text("Integer:")
            TextField("", text: $setting.displayVal, onEditingChanged: setting.CheckVal)
                .frame(width: 300.0)
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct DoubleEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            Text("Double:")
            TextField("", text: $setting.displayVal, onEditingChanged: setting.CheckVal)
                .frame(width: 300.0)
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct StringEntry: View {
    @ObservedObject var setting: SettingControl
    var body: some View {
        HStack {
            Text(setting.name)
                .font(.subheadline)
            Spacer()
            Text("String:")
            TextField("", text: $setting.displayVal, onEditingChanged: setting.CheckVal)
                .frame(width: 300.0)
        }
        .padding(.leading, 30.0)
        .padding([.top, .bottom, .trailing], 5.0)
    }
}

struct SolutionViews_Previews: PreviewProvider {
    static var previews: some View {
        let solution = SolutionCollection(solutionName: "morphic.solution.name")
        solution.settings.append(SettingControl(name: "FIRST SETTING", solname: "solution", type: .boolean))
        solution.settings.append(SettingControl(name: "SECOND SETTING", solname: "solution", type: .boolean))
        solution.settings.append(SettingControl(name: "THIRD SETTING", solname: "solution", type: .boolean))
        solution.settings.append(SettingControl(name: "FOURTH SETTING", solname: "solution", type: .boolean))
        let sec = SolutionSection(solution: solution)
        sec.active = true
        return sec
    }
}
