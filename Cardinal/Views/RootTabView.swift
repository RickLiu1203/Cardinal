import SwiftUI
import FirebaseAuth

struct RootTabView: View {
    let user: User
    @EnvironmentObject var formViewModel: FormViewModel
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ZStack {
                NavigationStack {   
                    HomeView(user: user, switchToTab: { tabIndex in
                        selectedTab = tabIndex
                    })
                }
                .opacity(selectedTab == 0 ? 1 : 0)
                .allowsHitTesting(selectedTab == 0)
                
                NavigationStack {
                    LogsView(ownerId: user.uid)
                }
                .opacity(selectedTab == 1 ? 1 : 0)
                .allowsHitTesting(selectedTab == 1)
                
                NavigationStack {
                    PortfolioView()
                }
                .opacity(selectedTab == 2 ? 1 : 0)
                .allowsHitTesting(selectedTab == 2)

                NavigationStack {
                    SettingsView()
                }
                .opacity(selectedTab == 3 ? 1 : 0)
                .allowsHitTesting(selectedTab == 3)
            }
            .animation(.none, value: selectedTab)
            
            // Custom neobrutalist tab bar
            HStack(spacing: 0) {
                CustomTabButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                CustomTabButton(
                    icon: "clock.fill",
                    title: "Logs",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                CustomTabButton(
                    icon: "person.crop.square",
                    title: "Portfolio",
                    isSelected: selectedTab == 2,
                    action: { selectedTab = 2 }
                )

                CustomTabButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .background(Color("BackgroundPrimary"))
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.black),
                alignment: .top
            )
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CustomTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
                
                Text(title)
                    .font(.custom("MabryPro-Medium", size: 12))
                    .foregroundColor(isSelected ? .white : .black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? .black : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}


