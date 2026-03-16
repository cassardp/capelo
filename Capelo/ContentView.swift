import SwiftUI

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            GameView()

            if showSplash {
                SplashView {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
