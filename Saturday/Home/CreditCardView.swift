//
//  CreditCardView.swift
//  Saturday
//
//  Created by Titus Lowe on 5/7/22.
//

import SwiftUI
import Kingfisher

struct CreditCardView: View {
    
    @EnvironmentObject var viewModel: UserViewModel
    
    let credit: Credit
    
    @State var isShowingPeekCreditView: Bool = false
    
    @State var isShowingCancelAlert: Bool = false
    
    @State var offset: CGFloat = 0
    
    @State var isSwiped: Bool = false
    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    @State var pauseNotification: Bool = false
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.systemRed]), startPoint: .leading, endPoint: .trailing)
            
            HStack {
                
                Spacer()
                    .frame(width: 256)
                
                Button {
                    viewModel.cacheTransaction(credit: credit)
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 80)
                
            }
            
            ZStack {
                
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(Color.background)
                    .frame(width: 320, height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(overdue() ? Color.systemRed : Color.clear, lineWidth: 8)
                    )
                
                HStack {
                    
                    KFImage(URL(string: debtor().profileImageUrl))
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.background, lineWidth: 3))
                    
                    VStack(alignment: .leading) {
                        
                        Text(credit.date)
                            .font(.system(size: 8))
                            .foregroundColor(Color.gray)
                            .padding(.leading, 4)
                        
                        Button {
                            NotificationManager.instance.sendDebtNotificationTo(creditor: viewModel.currentUser!, debtor: debtor(), amount: credit.total)
                            pauseNotification = true
                        } label: {
                            Text("Send a reminder")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white)
                                .frame(width: 112, height: 24)
                                .background(pauseNotification ? Color.gray : Color.systemViolet)
                                .cornerRadius(10)
                        }
                        .disabled(pauseNotification)
                        .onReceive(timer) { _ in
                            pauseNotification = false
                        }
                        
                        Button {
                            viewModel.refresh()
                            isShowingPeekCreditView = true
                        } label: {
                            Text("Preview")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white)
                                .frame(width: 112, height: 24)
                                .background(Color.systemIndigo)
                                .cornerRadius(10)
                        }
                        
                    }
                    .padding(.horizontal, 8)
                    
                    VStack(alignment: .trailing) {
                        
                        Text(userName())
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray)
                        
                        Text("$" + String(format: "%.2f", credit.total))
                            .font(.system(size: 20))
                        
                    }
                    .frame(width: 80)
                    
                }
                
            }
            .frame(width: 350, height: 150)
            .offset(x: offset)
            .gesture(DragGesture().onChanged(onChanged(value:)).onEnded(onEnd(value:)))
            .sheet(isPresented: $isShowingPeekCreditView) {
                PeekCreditView(credit: credit, isShowingPeekCreditView: $isShowingPeekCreditView)
                    .environmentObject(viewModel)
            }
            
        }
        .frame(width: 320, height: 96)
        .background(Color.background)
        .cornerRadius(25)
        .padding(.vertical, 8)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        .alert("Confirm Cancellation?", isPresented: $isShowingCancelAlert) {
            Button("Ok") {
                viewModel.refresh()
                viewModel.cacheTransaction(credit: credit)
                
            }
            Button("Cancel", role: .cancel) {
                print("ABORT: Credit Cancellation")
                withAnimation(.spring()) {
                    offset = 0
                }
            }
        }
        
    }
    
    func overdue() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm E, d MMM y"
        
        guard let creditDate = dateFormatter.date(from: credit.date) else { return false }
        return Calendar.current.numberOfDaysBetween(creditDate, and: Date.now) > 6
    }
    
    func debtor() -> User {
        let uid = credit.debtorId
        let debtor = viewModel.queryUser(withUid: uid)
        return debtor
    }
    
    func userName() -> String {
        let name = debtor().name.components(separatedBy: " ").first!

        if name.count > 6 {
            return name.prefix(5) + "..."
        } else {
            return name
        }
    }
    
    func resetOffset() {
        withAnimation(.easeIn) {
            offset = 0
        }
    }
    
    func onChanged(value: DragGesture.Value) {
        if value.translation.width < 0 {
            offset = value.translation.width
        }
    }
    
    func onEnd(value: DragGesture.Value) {
        withAnimation(.easeOut) {
            if value.translation.width < 0 {
                // Checking if ended
                if -value.translation.width > UIScreen.main.bounds.width / 2 {
                    offset = -1000
                    viewModel.refresh()
                    isShowingCancelAlert.toggle()
                } else if -offset > 48 {
                    // Updating is swiping
                    isSwiped = true
                    offset = -88
                } else {
                    isSwiped = false
                    offset = 0
                }
            } else {
                isSwiped = false
                offset = 0
            }
        }
    }
}

//struct CreditCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreditCardView(credit: previewCredit)
//            .environmentObject(UserViewModel())
//    }
//}
