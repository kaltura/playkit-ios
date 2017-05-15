//
//  PKStateMachine.swift
//  Pods
//
//  Created by Gal Orlanczyk on 02/04/2017.
//
//

import Foundation

protocol IntRawRepresentable: RawRepresentable {
    var rawValue: Int { get }
}

protocol StateProtocol: IntRawRepresentable, Hashable {}

extension StateProtocol {
    var hashValue: Int {
        return rawValue
    }
}

class BasicStateMachine<T: StateProtocol> {
    /// the current state.
    private var state: T
    /// the queue to make changes and fetches on.
    let dispatchQueue: DispatchQueue
    /// the initial state of the state machine.
    let initialState: T
    /// indicates whether it is allowed to change the state to the initial one.
    var allowTransitionToInitialState: Bool
    /// a block to perform on every state changing (performed on the main queue).
    var onStateChange: ((T) -> Void)?
    
    init(initialState: T, allowTransitionToInitialState: Bool = true) {
        self.state = initialState
        self.initialState = initialState
        self.allowTransitionToInitialState = allowTransitionToInitialState
        self.dispatchQueue = DispatchQueue(label: "com.kaltura.playkit.dispatch-queue.\(String(describing: type(of: self)))")
    }
    
    /// gets the current state.
    func getState() -> T {
        return self.dispatchQueue.sync {
            return self.state
        }
    }
    
    /// sets the state to a new value.
    func set(state: T) {
        self.dispatchQueue.sync {
            if state == self.initialState && !self.allowTransitionToInitialState {
                PKLog.error("\(String(describing: type(of: self))) was set to initial state, this is not allowed")
                return
            }
            // only set state when changed
            if self.state != state {
                self.state = state
                DispatchQueue.main.async {
                    self.onStateChange?(state)
                }
            }
        }
    }
    
    /// sets the state machine to the initial value.
    func reset() {
        dispatchQueue.sync {
            self.state = self.initialState
            DispatchQueue.main.async {
                self.onStateChange?(self.state)
            }
        }
    }
}
