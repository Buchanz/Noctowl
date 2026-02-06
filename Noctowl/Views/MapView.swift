import SwiftUI

struct MapView: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("Map")
                        .font(.system(size: 32, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ProfileButton { }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
        }
    }
}

#Preview {
    MapView()
}
