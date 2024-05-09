import SwiftUI

struct Toast: View {
    @Binding var isShowing:Bool
    @Binding var message:String
    let duration: TimeInterval
        
    var body: some View {
        ZStack{
            if isShowing{
                Spacer()
                HStack{
                    Text(message)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                .shadow(radius: 5)
            }
        }
        .padding()
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + duration){
                withAnimation{
                    isShowing = false
                }
            }
        }
    }
}
