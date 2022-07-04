//
//  LogInView.swift
//  Saturday
//
//  Created by Joshua Tan on 10/6/22.
//

import SwiftUI

struct LogInView: View {
    
    @EnvironmentObject var user: UserLoginModel
    
    @State var email = ""
    
    @State var password = ""
    
    var body: some View {
        
        NavigationView {
            
            ZStack {
                
                Color.systemBlue
                    .ignoresSafeArea()
                
                Circle()
                    .scale(1.7)
                    .foregroundColor(.white.opacity(0.15))
                
                Circle()
                    .scale(1.35)
                    .foregroundColor(.white)
                
                VStack {
                    
                    Text("Login")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .padding()
                    
                    TextField("Email", text: $email)
                        .multilineTextAlignment(.center)
                        .font(.system(.body, design: .rounded))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 300, height: 50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(50)
                    
                    Spacer()
                        .frame(height: 10)

                    SecureField("Password", text: $password)
                        .multilineTextAlignment(.center)
                        .font(.system(.body, design: .rounded))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 300, height: 50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(50)
                    
                    Spacer()
                        .frame(height: 10)

                    Button {
                        guard !email.isEmpty, !password.isEmpty else {
                            return
                        }
                        user.signIn(email: email, password: password)
                    } label: {
                        Text("Login")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 50)
                            .background(Color.systemBlue)
                            .cornerRadius(50)
                    }
                    
                    HStack {
                        Text("New around here?")
                            .font(.system(.headline, design: .rounded))
                        NavigationLink("Sign Up", destination:
                                        SignUpView()
                            .environmentObject(user))
                        .navigationBarHidden(true)
                        .foregroundColor(Color.systemBlue)
                        .font(.system(.subheadline, design: .rounded))
                        
                    }
                    
                }
                
            }
            .navigationBarHidden(true)
                
        }
//        VStack {
//
//            Spacer()
//
//            SaturdayLogo()
//                .frame(width: 300, height: 300, alignment: .center)
//
//            VStack {
//
//                TextField("Email", text: $email)
//                    .multilineTextAlignment(.center)
//                    .font(.system(.body, design: .rounded))
//                    .disableAutocorrection(true)
//                    .autocapitalization(.none)
//                    .padding()
//                    .background(Color(.secondarySystemBackground))
//                    .cornerRadius(50)
//
//                Spacer()
//                    .frame(height: 10)
//
//                SecureField("Password", text: $password)
//                    .multilineTextAlignment(.center)
//                    .font(.system(.body, design: .rounded))
//                    .disableAutocorrection(true)
//                    .autocapitalization(.none)
//                    .padding()
//                    .background(Color(.secondarySystemBackground))
//                    .cornerRadius(50)
//
//                Button(action: {
//
//                    guard !email.isEmpty, !password.isEmpty else {
//                        return
//                    }
//
//                    user.signIn(email: email, password: password)
//                }, label: {
//                    Text("Log In")
//                        .font(.system(.title3, design: .rounded))
//                        .fontWeight(.bold)
//                        .foregroundColor(Color.white)
//                        .frame(width: 200, height: 50)
//                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//                        .background(Color.systemBlue)
//                })
//                .cornerRadius(50)
//                .padding()
//
//                HStack {
//                    Text("New around here?")
//                        .font(.system(.headline, design: .rounded))
//                    NavigationLink("Sign Up", destination:
//                                    SignUpView()
//                        .environmentObject(user))
//                    .foregroundColor(Color.systemBlue)
//                    .font(.system(.subheadline, design: .rounded))
//
//                }
//
//            }
//            .padding(50)
//            .navigationTitle("Login")
//        }
    }
}


struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
            .environmentObject(UserLoginModel())
    }
}
