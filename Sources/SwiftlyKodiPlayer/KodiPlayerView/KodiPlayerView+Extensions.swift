//
//  KodiPlayerView+Extensions.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI

extension View {
    
    /// Add the controller to the player
    func controller() -> some View {
        modifier(KodiPlayerView.ShowControllerView())
    }
    
    /// Add gestures to the player
    func gestures() -> some View {
        modifier(KodiPlayerView.PlayerGestures())
    }
    
}

//extension EventModifiers {
//    static let none = Self()
//}
