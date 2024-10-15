//
//  AddressTextViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 25.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/*
 This model is needed to synchronize the heights of the address text field on
 destination and summary pages

 This is the result of the text field's implementation details -- the view is a
 SwiftUI wrapper over UIKit.UITextView.

 The UIKit view cannot tell us the height it needs at the time of creation because
 it doesn't know its width yet, because the width is set by SwiftUI system via the binding
 at a later time. This hack, this model, allows us to force the UIKit view to maintain its height
 during the animation from one page to another (one view to another)
 */
class AddressTextViewHeightModel: ObservableObject {
    @Published var height: CGFloat = 10
}
