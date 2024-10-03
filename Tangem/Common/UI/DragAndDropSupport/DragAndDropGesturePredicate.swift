//
//  DragAndDropGesturePredicate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

protocol DragAndDropGesturePredicate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
}
