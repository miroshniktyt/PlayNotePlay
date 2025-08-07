import SwiftUI

#Preview {
    OnboardingView()
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
    let color: Color
    let animation: Animation
}

let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        imageName: "music.note",
        title: "Welcome to Melody Memory!",
        description: "Train your musical ear by memorizing and recreating beautiful melodies. Start your journey to perfect pitch!",
        color: .cyan,
        animation: .spring(response: 0.6, dampingFraction: 0.6)
    ),
    OnboardingPage(
        imageName: "headphones",
        title: "Listen & Learn",
        description: "Each round starts by listening to a melody. Pay attention to the sequence of notes and their rhythm.",
        color: .blue,
        animation: .spring(response: 0.6, dampingFraction: 0.6)
    ),
    OnboardingPage(
        imageName: "hand.tap",
        title: "Recreate the Magic",
        description: "Use the colorful note buttons to recreate the melody you just heard. Each note has its unique sound and color.",
        color: .purple,
        animation: .spring(response: 0.6, dampingFraction: 0.6)
    ),
    OnboardingPage(
        imageName: "graduationcap.fill",
        title: "Progress Through Levels",
        description: "Start simple with 2 notes and work your way up to complex 9-note melodies. Unlock new levels by achieving streaks!",
        color: .green,
        animation: .spring(response: 0.6, dampingFraction: 0.6)
    ),
    OnboardingPage(
        imageName: "flame.fill",
        title: "Challenge Yourself",
        description: "Ready for the ultimate test? Try Challenge Mode with random melodies and compete for the highest streak!",
        color: .orange,
        animation: .spring(response: 0.6, dampingFraction: 0.6)
    )
]

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    
    var body: some View {
        ZStack {
            // Background gradient that changes with pages
            LinearGradient(
                gradient: Gradient(colors: [
                    onboardingPages[currentPage].color.opacity(0.3),
                    onboardingPages[currentPage].color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
                            VStack {
                HStack {
                    if hasSeenOnboarding {
                        Button(action: {
                            hasSeenOnboarding = true
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    
                    Spacer()
                    
                    if !hasSeenOnboarding {
                        Button(action: {
                            hasSeenOnboarding = true
                            dismiss()
                        }) {
                            if hasSeenOnboarding {
                                Image(systemName: "xmark")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                Text("Skip")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    }
                }
                
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { index, page in
                        VStack(spacing: 40) {
                            Image(systemName: page.imageName)
                                .font(.system(size: 100))
                                .foregroundColor(page.color)
                                .scaleEffect(isAnimating ? 1 : 0.5)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .animation(page.animation.repeatCount(1), value: isAnimating)
                            
                            VStack(spacing: 16) {
                                Text(page.title)
                                    .font(.title)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .opacity(isAnimating ? 1 : 0)
                                    .offset(y: isAnimating ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isAnimating)
                                
                                Text(page.description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .foregroundColor(.secondary)
                                    .opacity(isAnimating ? 1 : 0)
                                    .offset(y: isAnimating ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isAnimating)
                            }
                        }
                        .tag(index)
                        .padding(.bottom, 50)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .onChange(of: currentPage) { _ in
                    isAnimating = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isAnimating = true
                    }
                }
                
                Spacer()
                
                if currentPage == onboardingPages.count - 1 {
                    Button(action: {
                        hasSeenOnboarding = true
                        dismiss()
                    }) {
                        Text(!hasSeenOnboarding ? "Get Started" : "Got It!")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(onboardingPages[currentPage].color)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                } else {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(onboardingPages[currentPage].color)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
