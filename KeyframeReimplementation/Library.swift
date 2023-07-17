//

import Foundation
import SwiftUI

protocol MyKeyframeTracks<Root> {
    associatedtype Root

    func value(at time: TimeInterval, modify initial: inout Root)
}

protocol MyKeyframes<Value> {
    associatedtype Value

    var duration: TimeInterval { get }
    var to: Value { get }

    func interpolate(from: Value, time: TimeInterval) -> Value
}

struct MyKeyframeTimeline<Root> {
    var initialValue: Root
    var tracks: [any MyKeyframeTracks<Root>]

    func value(at time: TimeInterval) -> Root {
        var result = initialValue
        for track in tracks {
            track.value(at: time, modify: &result)
        }
        return result
    }
}

struct MyKeyframeTrack<Root, Value: Animatable>: MyKeyframeTracks {
    var keyPath: WritableKeyPath<Root, Value>
    var keyframes: [any MyKeyframes<Value>]

    func value(at time: TimeInterval, modify initial: inout Root) {
        initial[keyPath: keyPath] = value(at: time, initialValue: initial[keyPath: keyPath])
    }

    func value(at time: TimeInterval, initialValue: Value) -> Value {
        var currentTime: TimeInterval = 0
        var previousValue = initialValue
        for keyframe in keyframes {
            let relativeTime = time - currentTime
            defer { currentTime += keyframe.duration }
            guard relativeTime <= keyframe.duration else {
                previousValue = keyframe.to
                continue
            }

            return keyframe.interpolate(from: previousValue, time: relativeTime)
        }
        return keyframes.last?.to ?? initialValue
    }
}

struct MyLinearKeyframe<Value: Animatable>: MyKeyframes {
    var to: Value
    var duration: TimeInterval

    func interpolate(from: Value, time: TimeInterval) -> Value {
        let progress = time/duration
        var result = from
        result.animatableData.interpolate(towards: to.animatableData, amount: progress)
        return result
    }
}

struct MyMoveKeyframe<Value: Animatable>: MyKeyframes {
    var to: Value
    var duration: TimeInterval

    func interpolate(from: Value, time: TimeInterval) -> Value {
        to
    }
}
