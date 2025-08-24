import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("wind-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 96)
                .padding(.bottom, 24)

            Text("WELCOME TO RESPIRATIO")
                .font(.custom("Amagro-Bold", size: 24))
                .foregroundColor(.black)
                .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("\"With just five minutes of deliberate breathwork a day, you can significantly reduce stress more than a short meditation session.\"")
                    .font(.custom("AnekGujarati-Regular", size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                VStack(spacing: 8) {
                    Text("Dr. Andrew Huberman")
                        .font(.custom("AnekGujarati-Bold", size: 18))
                        .foregroundColor(.black)

                    Text("Professor of Neurobiology and Ophthalmology")
                        .font(.custom("AnekGujarati-Regular", size: 16))
                        .foregroundColor(.black.opacity(0.6))
                }
                .padding(.bottom, 16)

                Image("stanford-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            
            Spacer()

            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Navigate to main app
                onGetStarted()
            }) {
                HStack {
                    Text("Get Started")
                }
                .font(.custom("AnekGujarati-SemiBold", size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.215, green: 0.353, blue: 0.969))
                .cornerRadius(100)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
