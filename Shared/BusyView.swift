//
//  BusyView.swift
//  Rustom
//
//  Created by Vito Royeca on 8/16/22.
//

import SwiftUI

struct BusyView: View {
    var body: some View {
        ProgressView("Loading...")
            .progressViewStyle(.circular)
            .padding()
    }
}

struct BusyView_Previews: PreviewProvider {
    static var previews: some View {
        BusyView()
    }
}
