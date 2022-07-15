//
//  SideMenuView.swift
//  Saturday
//
//  Created by Titus Lowe on 4/7/22.
//

import SwiftUI

struct SideMenuView: View {
    
    @EnvironmentObject var viewModel: UserViewModel
    
    @Binding var isShowingSideMenu: Bool
    
    @State var isLoggingOut: Bool = false
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [Color.systemIndigo, Color.background]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                
                // MARK: Header
                SideMenuHeaderView(isShowingSideMenu: $isShowingSideMenu)
                    .environmentObject(viewModel)
                    .frame(height: 240)
                
                // MARK: Cell Items
                Button {
                    print("TODO: Profile View")
                } label: {
                    SideMenuOptionView(title: "Profile", imageName: "person")
                }
                
                Button {
                    print("TODO: Help View")
                } label: {
                    SideMenuOptionView(title: "Help", imageName: "questionmark.circle")
                }
                
                Button {
                    withAnimation(.spring()) {
                        viewModel.logout()
                    }
                } label: {
                    SideMenuOptionView(title: "Logout", imageName: "arrow.left.square")
                }
                
                Spacer()
                
            }
            
        }
        
    }
    
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(isShowingSideMenu: .constant(true))
            .environmentObject(UserViewModel())
    }
}
