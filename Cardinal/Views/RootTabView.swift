import SwiftUI
import FirebaseAuth

struct RootTabView: View {
    let user: User
    @EnvironmentObject var formViewModel: FormViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView(user: user)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            NavigationStack {
                DetailsFormView()
            }
            .tabItem {
                Image(systemName: "square.and.pencil")
                Text("Details")
            }
            
            NavigationStack {
                PortfolioView()
            }
            .tabItem {
                Image(systemName: "person.crop.square")
                Text("Portfolio")
            }
        }
    }
}


