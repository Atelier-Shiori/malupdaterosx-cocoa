 [![License](https://img.shields.io/badge/license-BSD-green.svg)](http://opensource.org/licenses/BSD-3-Clause)

# MAL Updater OS X 2.3
MAL Updater OS X is an open source OS X scrobbler that automatically detects what's playing and updates the user's MyAnimeList.

XCode 9 or higher is required to build (Deployment Target is OS X 10.9)

Note: Starting with MAL Updater OS X 2.2.7.1, the application is now Developer ID signed. In order to build, you need to have an Apple Developer ID certificate. Otherwise, you would need to disable code signing.

***This program is open source shareware and some features may require a license. Unofficial and self-compiled builds will recieve no support and may not use the default MAL API server (https://malapi.ateliershiori.moe). Doing so is a violation of terms of service.***

## Supporting this Project

Like this program and want to support the development of this program? Purchase a [Donation License](https://malupdaterosx.ateliershiori.moe/donate/). This allows us to help cover the costs of developing this program.

## How to use
Check the [Getting Started Guide](https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started)

## How to Compile in XCode
1. Get the Source
2. Type 'xcodebuild' to build. The build will be in the build/release folder.

## Building Textual Plugin

See readme.md in the MAL-Updater-OS-XTextualPlugin folder.

## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app:

* anitomy-osx.framework (MPL Licensed, included as a submodule)
* detectionkit.framework
* EasyNSURLConnection.framework
* MASPreferences.framework
* MASShortcut.framework
* Sparkle.framework
* CocoaOniguruma.framework
* Reachability.framework
* streamlinkdetect.framework

## License
Unless stated, Source code is licensed under [New BSD License](https://github.com/Atelier-Shiori/malupdaterosx-cocoa/blob/master/License.md).
