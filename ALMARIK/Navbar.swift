import SwiftUI
import Firebase

struct NavigationBarView: View {
    @Binding var isLoggedIn: Bool
    var LeftIcon: String
    var RightIcon: String
    
    @State private var isAnimated: Bool = false
    
    var body: some View {
        HStack {
            LogoView(textLeft: "ALMARIK", logo: "map")
                .opacity(isAnimated ? 1 : 0)
                .offset(x: 0, y: isAnimated ? 0 : -25)
                .onAppear(perform: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isAnimated.toggle()
                    }
                })
            
            Spacer()
            
            if (isLoggedIn){
                Button(action: {logout()}, label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title)
                        .foregroundColor(.black)
                })
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct LogoView: View {
    var textLeft: String
    var logo: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: logo)
                .resizable()
                .scaledToFit()
                .foregroundColor(.black)
                .frame(width: 30, height: 30, alignment: .center)
            
            Text(textLeft.uppercased())
                .font(.title3)
                .fontWeight(.black)
                .foregroundColor(.black)
            
        }
    }
}
