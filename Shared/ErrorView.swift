//
//  ErrorView.swift
//  Rustom
//
//  Created by Vito Royeca on 8/16/22.
//

import SwiftUI

struct ErrorView: View {
    var retryAction: () -> Void
    
    init(_ retryAction: @escaping () -> Void) {
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("An error has occured.")
            Button(action: {
                retryAction()
            }) {
                Text("Try again")
            }
            Spacer()
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView {
            print("Retry")
        }
    }
}
