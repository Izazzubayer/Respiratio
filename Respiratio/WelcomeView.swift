import SwiftUI

struct WelcomeView: View {
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

            Spacer()

            VStack {
                Text("\"With just five minutes of deliberate breathwork a day, you can significantly reduce stress more than a short meditation session.\"")
                    .font(.custom("AnekGujarati-Regular", size: 18))
                    .multilineTextAlignment(.center)
                    .kerning(-0.2)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                Text("Dr. Andrew Huberman")
                    .font(.custom("AnekGujarati-Bold", size: 16))
                    .foregroundColor(.black)

                Text("Professor of Neurobiology and Ophthalmology")
                    .font(.custom("AnekGujarati-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.bottom, 16)

                Image("stanford-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            
            Spacer()
            Spacer()

            Button(action: {
                // Action for get started
            }) {
                HStack {
                    Text("Get Started")
                }
                .font(.custom("AnekGujarati-SemiBold", size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
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
    WelcomeView()
}
