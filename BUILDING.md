# Building

We typically develop against the latest stable version of Xcode.

## 1. Clone

Clone the repo to a working directory:

```
git clone --recurse-submodules https://github.com/signalapp/Signal-iOS
```

Since we make use of sub-modules, you must use `git clone`, rather than
downloading a prepared zip file from Github.

We recommend you fork the repo on GitHub, then clone your fork:

```
git clone --recurse-submodules https://github.com/<USERNAME>/Signal-iOS.git
```

You can then add the Signal repo to sync with upstream changes:

```
git remote add upstream https://github.com/signalapp/Signal-iOS
```

## 2. Dependencies

To build and configure the libraries Signal uses, just run:

```
make dependencies
```

## 3. Xcode

Open the `Signal.xcworkspace` in Xcode.

```
open Signal.xcworkspace
```

Show the Navigator by pressing <kbd>⌘</kbd> + <kbd>1</kbd>. In the Navigator,
select the Signal project. The project's settings will appear in the editor
area. Select the "Signal" target to view the target's settings.

Under the Signing & Capabilities tab, change the Team drop down to
your own. You will need to do that for all the listed targets, for ex. Signal,
SignalShareExtension, and SignalNSE. You will need an Apple Developer account
for this.

Returning to the Signal target, under the same tab, delete the capability
sections for Push Notifications, Apple Pay, In-App Purchases, Communication
Notifications, and Data Protection.

The App Groups capability will need to remain on in order to access the shared
data storage. The best way to change the bundle ID for the app groups is
setting `SIGNAL_BUNDLEID_PREFIX` in the project's settings.

If you wish to test the Documents API, the iCloud capability will need to be on
with the iCloud Documents option selected.

Build and Run and you are ready to go!


## Known issues

Features related to push notifications are known to be not working for
third-party contributors since Apple's Push Notification service pushes
will only work with Open Whisper Systems production code signing
certificate.

Turn on Push Notifications on the Capabilities tab if you want to register a new Signal account using the application installed via XCode.

If you have any other issues, please ask on the [community forum](https://community.signalusers.org/).
