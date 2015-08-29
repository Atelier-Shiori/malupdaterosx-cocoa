[![Build Status](https://travis-ci.org/chikorita157/malupdaterosx-cocoa.svg?branch=master)](https://travis-ci.org/chikorita157/malupdaterosx-cocoa) [![License](https://img.shields.io/badge/license-BSD-green.svg)](http://opensource.org/licenses/BSD-3-Clause)

# MAL Updater OS X 2.2
MAL Updater OS X is an open source OS X scrobbler that automatically detects what's playing and updates the user's MyAnimeList.

XCode 6.1 or higher is required to build (Deployment Target is OS X 10.8)

Like this program and want to support the development of this program? [Become our Patreon](http://www.patreon.com/chikorita157)

Note: Starting with MAL Updater OS X 2.2.7.1, the application is now Developer ID signed. In order to build, you need to have an Apple Developer ID certificate. Otherwise, you would need to disable code signing.

## How to use
Check the [Getting Started Guide](https://github.com/chikorita157/malupdaterosx-cocoa/wiki/Getting-Started)

## How to Compile in XCode
1. Get the Source
2. Type 'xcodebuild' to build. The build will be in the build/release folder.

## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app:

* anitomy-osx.framework (GPLv3 Licensed, included as a submodule)
* Sparkle.framework
* OgreKit.framework

##License
Copyright © 2009-2015, Atelier Shiori.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 

3. Neither the name of the Atelier Shiori nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.