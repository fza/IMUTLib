# IMUT

– an iOS framework for Usability and User Experience testing in the field. Suitable for applications deployed for iOS 7+.

## Main features

* Screen and face recording
* Sensor and UI logging (see **Configuration** below)
* Extendable by custom modules
* Records and logs all data in sync with the screen video
* Generates a single log file in `json` format

## Installation

* Copy/reference the `IMUT.framework` and `IMUT.plist` in your Xcode project.
* Edit the `IMUT.plist` file to suit your needs. (see **Configuration** below)
* Add `IMUT.framework` to the `Link Binary With Libraries` list in your build target.
* Make sure to link your application against the following system frameworks. These are also referenced in the `IMUT.h` header file.
	* AVFoundation
	* CoreGraphics
	* CoreLocation
	* CoreMedia
	* CoreVideo
    * Foundation
	* ImageIO
	* UIKit
* In your `UIApplicationDelegate` subclass, add `#import <IMUT/IMUT.h>` at the top.
* As early as possible inside your `application:willFinishLaunchingWithOptions:` method, add: `[IMUTLibMain setup]`.

## Configuration

Use the `IMUT.plist` file to configure the library.

* `autostart` (type: `Boolean`, default: `YES`) Wether IMUT should start automatically when the application did finish launching.
* `synchronizationInterval` (type: `Number`, default: `0.5`) An interval between 0.25 and 5 seconds for IMUT to aggregate events before writing a new log packet.
* `keepUnfinishedFiles` (type: `Boolean`, default: `NO`) Wether to keep unfinished files from previous sessions.
* `modules` (type: `Dictionary`, **mandatory**) The modules to activate. Each item is a `Boolean` value.
	* `backlight`
	* `batteryLevel`
	* `batteryState`
	* `frontCamera`
	* `heading`
	* `location`
	* `orientation`
	* `screenRecorder`
	* `uiViewController`

## Usage

IMUT is designed to be as transparent as possible, so that testers should ideally not perceive that IMUT is actually running. Thus, as soon as you call the `start` method or set `autostart` to `YES` the library will immediately begin recording and logging upon application launch or resume without any necessary user interaction.

Due to platform constraints there may be some inconveniences, though. E.g. the location module needs access to the location data, which will cause the OS to display a notification upon first request. If the user decides not to enable this functionality, the module will be disabled at runtime. However, this means that the log file includes the module as being enabled, although it may be disabled shortly after the logger began writing and no locationChange events will be logged.

## Generated files

The files generated during runtime are stored in the application library directory. Look for a subdirectory named `IMUT`. You may use Xcode's Organizer tool to download the application files from your device. If you run the application inside the simulator the application library directory is typically located at `~/Library/Application Support/iPhone Simulator/[Version]/[UUID]/Library`.

## License

See the LICENSE file.
