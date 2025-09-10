import SwiftUI

struct ContentView: View {
    @State private var page = 0
    var body: some View {
        TabView(selection: $page) {
            CoverPageView().tag(0)
            HomePage().tag(1)   // ← 仮のHomePageでOK
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .all)
    }
}
