import SwiftUI

struct ContentView: View {
    @State private var page = 0
    
    // 🟢 これを追加
    @StateObject private var router = Router()
    @StateObject private var hw = HomeworkState()

    var body: some View {
        TabView(selection: $page) {
            CoverPageView()
                .environmentObject(router)
                .environmentObject(hw)
                .tag(0)

            HomePage()
                .environmentObject(router)
                .environmentObject(hw)
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .all)
    }
}
