//
//  KodiPlayerView+Extensions.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI

extension View {
    func controller() -> some View {
        modifier(KodiPlayerView.ShowControllerView())
    }
}
