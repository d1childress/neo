import SwiftUI

struct Sidebar: View {
    var body: some View {
        ZStack(alignment: .leading) {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            Text("Sidebar Content")
        }
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
} 