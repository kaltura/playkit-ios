//
//  DataConsumptionLogic.swift
//  BasicSample
//
//  Created by Gal Orlanczyk on 14/06/2017.
//  Copyright © 2017 Kaltura. All rights reserved.
//

import Foundation

@objc public class PKDoubleRange: NSObject {
    let lowerBound: Double
    let upperBound: Double
    
    @objc public init(lowerBound: Double, upperBound: Double) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

@objc public class PKForwardBufferDecisionRanges: NSObject {
    let valueRanges: [PKDoubleRange]
    let scoreRanges: [PKDoubleRange]
    
    @objc public init?(valueRanges: [PKDoubleRange], scoreRanges: [PKDoubleRange]) {
        guard valueRanges.count == scoreRanges.count else { return nil }
        self.valueRanges = valueRanges
        self.scoreRanges = scoreRanges
    }
}

class ForwardBufferLogic {
    
    enum LogicType {
        case duration(duration: TimeInterval)
        case userEngagementAndDuration(engagement: TimeInterval, duration: TimeInterval)
    }
    
    static var maxForwardBuffer: TimeInterval = 50.0
    static var minForwardBuffer: TimeInterval = 21.0
    
    let defaultEngagementAndDurationRanges = PKForwardBufferDecisionRanges(
        valueRanges: [
            PKDoubleRange(lowerBound: 0, upperBound: 5*60),
            PKDoubleRange(lowerBound: 5*60, upperBound: 10*60),
            PKDoubleRange(lowerBound: 10*60, upperBound: 20*60),
            PKDoubleRange(lowerBound: 20*60, upperBound: 30*60)
        ],scoreRanges: [
            PKDoubleRange(lowerBound: 0.6, upperBound: 0.78),
            PKDoubleRange(lowerBound: 0.78, upperBound: 0.88),
            PKDoubleRange(lowerBound: 0.88, upperBound: 0.95),
            PKDoubleRange(lowerBound: 0.95, upperBound: 1)
        ])!
    
    let defaultDurationRanges = PKForwardBufferDecisionRanges(
        valueRanges: [
            PKDoubleRange(lowerBound: 0, upperBound: 5*60),
            PKDoubleRange(lowerBound: 5*60, upperBound: 10*60),
            PKDoubleRange(lowerBound: 10*60, upperBound: 15*60),
            PKDoubleRange(lowerBound: 15*60, upperBound: 20*60)
        ],scoreRanges: [
            PKDoubleRange(lowerBound: 0.6, upperBound: 0.7),
            PKDoubleRange(lowerBound: 0.7, upperBound: 0.8),
            PKDoubleRange(lowerBound: 0.8, upperBound: 0.9),
            PKDoubleRange(lowerBound: 0.9, upperBound: 1)
        ])!
    
    var customDurationDecisionRanges: PKForwardBufferDecisionRanges?
    
    init(customDurationDecisionRanges: PKForwardBufferDecisionRanges? = nil) {
        self.customDurationDecisionRanges = customDurationDecisionRanges
    }
    
    func getDuration(for logicType: LogicType) -> TimeInterval {
        var durationScore: Double = 1.0
        var engagementScore: Double = 1.0
        
        switch logicType {
        case .duration(let duration):
            if let customDurationDecisionRanges = self.customDurationDecisionRanges {
                durationScore = self.calculateScore(forDuration: duration, withDecisionRange: customDurationDecisionRanges)
            } else {
                durationScore = self.calculateScore(forDuration: duration, withDecisionRange: defaultDurationRanges)
            }
        case .userEngagementAndDuration(let engagement, let duration):
            durationScore = self.calculateScore(forDuration: duration, withDecisionRange: defaultEngagementAndDurationRanges)
            engagementScore = self.calculateScore(forEngagement: Double(engagement), withDuration: duration, andDurationScore: durationScore)
        }
        
        let forwardBufferSize: TimeInterval = durationScore * engagementScore * ForwardBufferLogic.maxForwardBuffer
        
        if forwardBufferSize >= ForwardBufferLogic.maxForwardBuffer {
            return ForwardBufferLogic.maxForwardBuffer
        } else if forwardBufferSize > ForwardBufferLogic.minForwardBuffer && forwardBufferSize < ForwardBufferLogic.maxForwardBuffer {
            return forwardBufferSize
        } else {
            return ForwardBufferLogic.minForwardBuffer
        }
    }
    
    private func calculateScore(forDuration duration: TimeInterval, withDecisionRange decisionRange: PKForwardBufferDecisionRanges) -> Double {
        return self.calculateScore(usingValue: duration,
                                   fromScoreRange: decisionRange.scoreRanges,
                                   andValueRange: decisionRange.valueRanges,
                                   maxValue: decisionRange.scoreRanges.last!.upperBound)
    }
    
    private func calculateScore(forEngagement engagement: TimeInterval, withDuration duration: TimeInterval, andDurationScore durationScore: Double) -> Double {
        let engagementRatio = engagement / duration * 100
        
        let valueRanges = [
            PKDoubleRange(lowerBound: 0, upperBound: 3),
            PKDoubleRange(lowerBound: 3, upperBound: 8),
            PKDoubleRange(lowerBound: 8, upperBound: 13),
            PKDoubleRange(lowerBound: 13, upperBound: 20)
        ]
        let scoreRanges = [
            PKDoubleRange(lowerBound: 0.45 * durationScore, upperBound: 0.8 * durationScore),
            PKDoubleRange(lowerBound: 0.8 * durationScore, upperBound: 0.9 * durationScore),
            PKDoubleRange(lowerBound: 0.9 * durationScore, upperBound: 1.0 * durationScore),
            PKDoubleRange(lowerBound: 1.0 * durationScore, upperBound: 1.05 * durationScore)
        ]
        
        return self.calculateScore(usingValue: engagementRatio, fromScoreRange: scoreRanges, andValueRange: valueRanges, maxValue: scoreRanges.last!.upperBound)
    }
    
    private func calculateScore(usingValue value: Double, fromScoreRange scoreRanges: [PKDoubleRange], andValueRange valueRanges: [PKDoubleRange], maxValue: Double) -> Double {
        // inner helper func
        func calculateScore(fromScoreRange scoreRange: PKDoubleRange, andValueRange valueRange: PKDoubleRange, withValue value: Double) -> Double {
            return (scoreRange.upperBound - scoreRange.lowerBound) * (1 / (valueRange.upperBound - valueRange.lowerBound)) * (value - valueRange.lowerBound)
        }
        
        guard let maxRange = valueRanges.last, value < maxRange.upperBound else { return maxValue }
        
        var score = scoreRanges.first!.lowerBound
        for (index, valueRange) in valueRanges.enumerated() {
            if value >= valueRange.upperBound {
                score += calculateScore(fromScoreRange: scoreRanges[index], andValueRange: valueRange, withValue: valueRange.upperBound)
            } else if value > valueRange.lowerBound && value <= valueRange.upperBound {
                score += calculateScore(fromScoreRange: scoreRanges[index], andValueRange: valueRange, withValue: value)
                return score
            } else {
                return score
            }
        }
        return score
    }
}
