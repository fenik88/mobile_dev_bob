import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0

    var body: some View {
        if isActive {
            MainTabView()
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(.blue)

                    Text("FlashWords")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(NSLocalizedString("splash_subtitle", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeIn(duration: 0.3)) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}
