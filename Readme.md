# MAL Updater OS X 2.1 Cocoa
MAL Updater OS X is an open source Mac OS X application that automatically detects what's playing and updates the user's MyAnimeList.

Requires Mountain Lion SDK. (XCode 5)

#Notes#
I am making changes to the code to make it compatible with Mountain Lion features, update frameworks and ARC compatability. Therefore, MAL Updater OS X 2.1.5 or later requires Mountain Lion or Later.

## How to use
To use, launch MAL Updater OS X. Go to the MAL Updater OS X icon on the menu bar and Preferences. Save your login info (encoded in Base64 in Preferences) and click Start Scrobbling.

## How to Compile in XCode
1. Get the Source
2. Type 'xcodebuild' to build

## Dependencies
All the frameworks are included. Just build! Here are the frameworks that are used in this app:

* CMCrashReporter.framework
* Sparkle.framework
* OgreKit.framework
* Growl.framework (Removed in 2.1.5, hopefully)
* JSON.framework

##License
Copyright © 2009-2014, Atelier Shiori.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 
3. Neither the name of the Atelier Shiori g nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.