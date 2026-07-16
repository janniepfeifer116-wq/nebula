1 On the phone: Settings → Privacy & Security → Developer Mode → on (it reboots once).

2 In Config/AppConfig.xcconfig: set the bundle id you want to test under, and optionally your Team ID (or pick the team in Xcode instead).

3 cd 2026-07/nebula-stats && xcodegen generate && open NebulaStats.xcodeproj

4 In Xcode: target NebulaStats → Signing & Capabilities → "Automatically manage signing" → choose your team (add your Apple ID under Xcode → Settings → Accounts if it's not listed).

5 Plug in the iPhone (tap "Trust"), select it in the device picker, hit Run. First launch: Settings → General → VPN & Device Management → trust your developer certificate.

6 With a free Apple ID the install expires after 7 days — just Run again from Xcode.
