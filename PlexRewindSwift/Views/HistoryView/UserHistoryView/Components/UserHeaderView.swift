import SwiftUI

struct UserHeaderView: View {
    @ObservedObject var viewModel: UserHistoryViewModel

    var body: some View {
        Section {
            VStack(spacing: 15) {
                AsyncImageView(url: viewModel.userProfileImageURL)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                
                Text(viewModel.userName)
                    .font(.title.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
