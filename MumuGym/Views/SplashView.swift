import SwiftUI

struct SplashView: View {
    @State private var isLoading = true
    @State private var scale = 0.5
    @State private var opacity = 0.0
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            themeManager.currentBackgroundGradient
            
            VStack(spacing: 20) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.cardBackground)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("MumuGym")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.cardBackground)
                    .opacity(opacity)
                
                Text("Your Personal Fitness Companion")
                    .font(.subheadline)
                    .foregroundColor(.surfaceBackground)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
