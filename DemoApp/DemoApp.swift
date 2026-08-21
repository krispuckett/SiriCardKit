// The demo app is deliberately almost nothing: it exists so the intents
// have a host and so the judging stage has a home. Your card ships inside
// YOUR app; this project is the workshop, not the product.
//
// Do not publish this demo to the App Store. Apple's guidelines treat
// commercialized template apps as spam (4.2.6, 4.3a). The kit's shape is
// "add this feature to your existing app".

import SwiftUI

@main
struct SiriCardKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            CardPreviewStage()
                .preferredColorScheme(.dark)
        }
    }
}
