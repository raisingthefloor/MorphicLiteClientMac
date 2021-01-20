// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

public class AsyncUtils {
    public static func wait(atMost: TimeInterval, for condition: @escaping () -> Bool, completion: @escaping (_ success: Bool) -> Void) {
        guard !condition() else {
            completion(true)
            return
        }
        var checkTimer: Timer?
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: atMost, repeats: false) {
            _ in
            checkTimer?.invalidate()
            completion(condition())
        }
        var checkInterval: TimeInterval = 0.1
        var check: (() -> Void)!
        check = {
            checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: false) {
                _ in
                if condition() {
                    timeoutTimer.invalidate()
                    completion(true)
                } else {
                    checkInterval *= 2
                    check()
                }
            }
        }
        check()
    }
    
    public static func syncWait(atMost: TimeInterval, for condition: @escaping () -> Bool) {
        var conditionIsMet = false

        let conditionLock = NSCondition()
        conditionLock.lock()
        defer {
            conditionLock.unlock()
        }
        
        guard !condition() else {
            return
        }
        var checkTimer: Timer?
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: atMost, repeats: false) {
            _ in
            checkTimer?.invalidate()
            conditionIsMet = true
            conditionLock.signal()
        }
        var checkInterval: TimeInterval = 0.1
        var check: (() -> Void)!
        check = {
            checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: false) {
                _ in
                if condition() {
                    timeoutTimer.invalidate()
                    conditionIsMet = true
                    conditionLock.signal()
                } else {
                    checkInterval *= 2
                    check()
                }
            }
        }
        check()

        while conditionIsMet == false {
            // NOTE: we use waitInterval for the extreme edge case that the condition was met in a timeslice between when we checked and when we started to wait
            let waitInterval: TimeInterval = 0.1
            conditionLock.wait(until: Date().addingTimeInterval(waitInterval))
        }
    }
}
