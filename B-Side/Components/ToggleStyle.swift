//
//  ToggleStyle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import SwiftUI

struct BSideToggleStyle: ToggleStyle {

    func makeBody(configuration: Configuration) -> some View {

        HStack {

            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    configuration.isOn
                    ? Color.bSideBlue
                    : Color.blue2
                )
                .frame(
                    width: 52,
                    height: 30
                )
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(
                            width: 24,
                            height: 24
                        )
                        .offset(
                            x: configuration.isOn ? 11 : -11
                        )
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: configuration.isOn
                        )
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
