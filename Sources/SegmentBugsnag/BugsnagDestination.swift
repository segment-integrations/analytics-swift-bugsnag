//
//  BugsnagDestination.swift
//  BugsnagDestination
//
//  Created by Komal Dhingra on 12/06/22.

// MIT License
//
// Copyright (c) 2021 Segment
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Segment
import Bugsnag

public class BugsnagDestination: DestinationPlugin {
    public let timeline = Timeline()
    public let type = PluginType.destination
    public let key = "Bugsnag"
    public var analytics: Analytics? = nil
                
    public init() { }

    public func update(settings: Settings, type: UpdateType) {
        // Skip if you have a singleton and don't want to keep updating via settings.
        guard type == .initial else { return }
        
        guard let bugsnagSettings: BugsnagSettings = settings.integrationSettings(forPlugin: self) else { return }
                        
        //Bugsnag initialized with apikey
        Bugsnag.start(withApiKey: bugsnagSettings.apiKey)
        
    }

    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        
        if let traits = event.traits?.dictionaryValue, let email = traits["email"] as? String, let name = traits["name"] as? String{
            if let userId = event.userId{
                Bugsnag.setUser(userId, withEmail: email, andName: name)

            }else{
                Bugsnag.setUser(event.anonymousId, withEmail: email, andName: name)
            }
            
            traits.forEach { key, value in
                Bugsnag.addMetadata(value, key: key, section: "user")
            }            
        } else {
            Bugsnag.setUser(event.userId ?? event.anonymousId ?? nil, withEmail: nil, andName: nil)
            Bugsnag.notifyError(NSError(domain: "Email & Name not found!", code: 404))
        }
        
        return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        
        Bugsnag.leaveBreadcrumb(event.event, metadata: event.properties?.dictionaryValue, type: .log)

        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        
        Bugsnag.setContext(event.name)
        
        if let eventName = event.name {
            Bugsnag.leaveBreadcrumb(withMessage: "Viewed \(eventName) Screen")
        }
        return event
    }
    
    public func reset() {
        Bugsnag.clearMetadata(section: "user")
    }
 
}

extension BugsnagDestination: VersionedPlugin {
    public static func version() -> String {
        return __destination_version
    }
}

private struct BugsnagSettings: Codable {
    let apiKey: String
    let releaseStage: String?
    let useSSL: Bool?
}

