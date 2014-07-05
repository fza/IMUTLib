# IMUT

– an iOS framework for Usability and User Experience testing in the field. Suitable for applications deployed for iOS 7+.

## Main features

* Screen and face recording
* Sensor and UI logging (see **Configuration** below)
* Extendable by custom modules
* Records and logs all data in sync with a single time source (typically the screen video)
* Generates a single log file in `json` format, which can be easily parsed

## Installation

* Add the `IMUT.framework` and `IMUT.plist` direcoty/file to your project.
* Edit the `IMUT.plist` file to suit your needs. (see **Configuration** below)
* Add `IMUT.framework` to the `Link Binary With Libraries` list in your build target.
* Make sure to link your application against the following system frameworks:
	* AVFoundation
	* CoreGraphics
	* CoreLocation
	* CoreVideo
    * Foundation
	* ImageIO
	* UIKit
* In your `UIApplicationDelegate` subclass, add `#import <IMUT/IMUTLibMain.h>` at the top.
* Somewhere inside your `application:didFinishLaunchingWithOptions:` **OR** `application:willFinishLaunchingWithOptions:` method, add: `[IMUTLibMain setup]`. Calling this method twice has no effect but produces a debug notice.

## Configuration

Use the `IMUT.plist` file to configure the library.

* `autostart` (type: `Boolean`, default: `YES`) Wether IMUT should start automatically when the application did finish launching.
* `synchronizationInterval` (type: `Number`, default: `0.5`) An interval between 0.25 and 5 seconds for IMUT to aggregate events before writing a new log packet.
* `keepUnfinishedFiles` (type: `Boolean`, default: `NO`) Wether to keep unfinished files from previous sessions.
* `modules` (type: `Dictionary`, **mandatory**) The modules to activate. Each item can be a `Boolean` to simply indicate that the module should be enabled or another `Dictionary` for fine grained module configuration, if the module can be configured at all.
	* `acceleration`
	* `appStatus`
	* `backlight`
	* `batteryLevel`
	* `batteryStatus`
	* `cameraAction`
	* `gestureAction`
	* `heading`
	* `location`
	* `networkConnectivity`
	* `orientation`
	* `screenRecorder` Configuration available.
		* `hidePasswordInput` (type: `Boolean`, default: `YES`)
		* `useLowResolution` (type: `Boolean`, default: `NO`)
	* `faceRecorder`
		* `useLowResolution` (type: `Boolean`, default: `NO`)
	* `microphoneRecorder`
	* `uiViewController` 

### Note on the face and microphone recorder

The face and microphone recorder share a single media file. If only the microphone recorder is active, the library will create a simple `mp3` file. In the other cases this is a `m4v` media container.

## Usage

IMUT is designed to be as transparent as possible, so that testers should ideally not perceive that IMUT is actually running. Thus, as soon as you call the `start` method or set `autostart` to `YES` the library will immediately begin recording and logging upon application launch or resume without any necessary user interaction.

Due to platform constraints there may be some inconveniences, though. E.g. the location module needs access to the location data, which will cause the OS to display a notification upon first request. If the user decides not to enable this functionality, the module will be disabled at runtime, though this may happen at a time when IMUT had been already initialized. This means that the log file includes the module as being enabled, although it was disabled shortly after the logger began writing the file and not locationChange events will be logged.

## Generated files

The files generated during runtime are stored in the application library directory. Look for a subdirectory named `IMUT`. You may use Xcode's Organizer tool to download the application files from your device. If you run the application in the simulator the application library directory should be present at `~/Library/Application Support/iPhone Simulator/[Version]/[UUID]/Library`.

## Extending IMUT

You may extend IMUT by writing your own logging modules and register them at runtime. Note that you must enable your modules in the `IMUT.plist` file in order for them to be recognized by the library. The `autostart` setting must be `NO` and you must invoke the `start` method on the shared `IMUTLibMain` instance manually after you registered the module in your application launch method. At least a library consists of two classes, a module class and a source event class. Plus you have to define a specific aggregator block.

1. Your module must conform to the `IMUTLibModule` protocol and must have a unique name that must be used in the configuration file. You typically want to use the `IMUTLibAbstractModule` class to implement your module. The `moduleType` method must always return `IMUTLibModuleTypeDataEvents`. A module class is responsible for observing events, create specific objects (see 3.) and inject those objects into the library's owned aggregator. The latter can be accessed using `[IMUTLibEventAggregator sharedInstance]`.
2. Your module is initialized using the `initWithConfig:` method and is passed a pointer to a `NSDictionary` object containing your module configuration. You may decide to implement the `defaultConfig` method if you want IMUT to merge any manual `IMUT.plist` module specific configuration with your defaults. Note that IMUT does not perform a deep merge!
3. A module class must also conform to the `IMUTLibEventAggregator`. The aggregator registry will then call back the module and ask for specific aggregator blocks, i.e. anonymous functions in Obj-C. These blocks are passed two source events and must decide if they differ as much as necessary in order for the aggregator to be able to create an `IMUTLibDeltaEntity` object, which the block should return, or `nil` otherwise. Each event type must have one associated aggregator. An aggregator can handle multiple event types.
4. A source event class must be implemented according to the `IMUTLibSourceEvent` protocol and should include only as much information as needed for the aggregator block to do its job. The more data is stored in a source event object, the slower IMUT becomes.
5. An aggregator block and the source events it should handle must be given an internal, but unique key.
6. A `IMUTLibDeltaEntity` object must be created using the `entityWithKey:parameters:sourceEvent:` class method. The key and parameters are used to generate the packet in the log file.
7. A module may and should respond to the `start`, `pause`, `resume` and `terminate` callbacks, though it may produce events at any time and enqueue them using the aggregator. IMUT does not ensure that all events will be considered, but ensures that events will be handled in the same order they were produced. Thus, when the application is about to become idle or terminates in the normal way, events generated after the internal clock stopped are unconsidered.

For further information see the corresponding header files.

## License

See the LICENSE file.
