import SwiftUI

struct BSideToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
        }
        .toggleStyle(.switch)
        .tint(Color.accentPrimary)
        .frame(minHeight: BSideLayout.minimumTouchTarget)
    }
}
