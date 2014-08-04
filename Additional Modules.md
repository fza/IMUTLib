# IMUT Modules

## Already present in current prototype:

* `backlight` – Tracks the displays brightness value
* `batteryLevel` – Tracks the battery level
* `batteryStatus` – Tracks battery status events
* `heading` – Tracks heading changes
* `location` – Tracks location changes
* `screenRecorder` – Records the screen
* `orientation` – Observes the device orientation
* `frontRecorder` – Records the front camera
* `uiViewController` – Tracks changes of the current UIViewController class, if possible (depends on the app's UI architecture)

## Proposed, not yet implemented:

* `acceleration` – Tracks the device acceleration
* `cpuUsage` – Tracks the CPU usage
* `memoryUsage` – Tracks the app's/system's memory usage
* `fps` – Tracks the interface's frames per second value as rendered by the GPU
* `cameraAction`– Tacks status events when the user selects a photo from the camera roll or takes a new one
* `gestureAction` – Tracks all the user's gesture actions (pinch, zoom, slide etc.)
* `networkConnectivity` – Tracks status events when connectivity is detected/lost
* `orientation` – Extension to distinguish between interface/device orientation
* `mainCamera` – Records the main camera 
* `microphoneRecorder` – Records the microphone
* `customEvents` – Ability to track custom events generated by the application
* `gyroscope` – Track the device's position/orientation in 3D space