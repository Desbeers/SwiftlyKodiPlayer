//
//  KodiPlayerView+tvOS.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import AVFoundation
import AVKit
import SwiftUI
import KSPlayer
import SwiftlyKodiAPI

#if os(tvOS)
import Combine

extension KodiPlayerView {
    
    public struct ShowControllerView: ViewModifier {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerView.PlayerModel
        
        public func body(content: Content) -> some View {
            content
                .fullScreenCover(isPresented: $playerModel.showController) {
                    VStack {
                        Spacer()
                        ControllerView()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
        }
    }
    
    public struct Slider: UIViewRepresentable {
        private let process: Binding<Float>
        private let onEditingChanged: (Bool) -> Void
        init(value: Binding<Double>, in bounds: ClosedRange<Double> = 0 ... 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
            process = Binding {
                Float((value.wrappedValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
            } set: { newValue in
                value.wrappedValue = (bounds.upperBound - bounds.lowerBound) * Double(newValue) + bounds.lowerBound
            }
            self.onEditingChanged = onEditingChanged
        }
        
        public typealias UIViewType = TVSlide
        public func makeUIView(context _: Context) -> UIViewType {
            TVSlide(process: process, onEditingChanged: onEditingChanged)
        }
        
        public func updateUIView(_ view: UIViewType, context _: Context) {
            view.process = process
            view.tintColor = view.isFocused ? .white : .black
        }
    }
    
    public class TVSlide: UIControl {
        private let processView = UIProgressView()
        private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(actionPanGesture(sender:)))
        private var beganProgress = Float(0.0)
        private let onEditingChanged: (Bool) -> Void
        fileprivate var process: Binding<Float> {
            willSet {
                if newValue.wrappedValue != processView.progress {
                    processView.progress = newValue.wrappedValue
                }
            }
        }
        
        public init(process: Binding<Float>, onEditingChanged: @escaping (Bool) -> Void) {
            self.process = process
            self.onEditingChanged = onEditingChanged
            super.init(frame: .zero)
            processView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(processView)
            NSLayoutConstraint.activate([
                processView.topAnchor.constraint(equalTo: topAnchor),
                processView.leadingAnchor.constraint(equalTo: leadingAnchor),
                processView.trailingAnchor.constraint(equalTo: trailingAnchor),
                processView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            addGestureRecognizer(panGestureRecognizer)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(actionTapGesture(sender:)))
            addGestureRecognizer(tapGestureRecognizer)
        }
        
        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func actionTapGesture(sender _: UITapGestureRecognizer) {
            panGestureRecognizer.isEnabled.toggle()
            processView.tintColor = panGestureRecognizer.isEnabled ? .blue : .white
        }
        
        @objc private func actionPanGesture(sender: UIPanGestureRecognizer) {
            let translation = sender.translation(in: self)
            if abs(translation.y) > abs(translation.x) {
                return
            }
            
            switch sender.state {
            case .began, .possible:
                beganProgress = processView.progress
            case .changed:
                let value = beganProgress + Float(translation.x) / 5 / Float(frame.size.width)
                process.wrappedValue = value
                onEditingChanged(true)
            case .ended:
                onEditingChanged(false)
            case .cancelled, .failed:
                process.wrappedValue = beganProgress
                onEditingChanged(false)
            @unknown default:
                break
            }
        }
    }
}
#endif
