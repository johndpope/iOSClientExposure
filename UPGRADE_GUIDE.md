# Upgrade Guide

## 0.72.0 to 0.77.0

#### Architecture
`Exposure` module has been refactored with the playback and download related functionality extracted into new modules, `ExposurePlayback` and `ExposureDownload`.

`Exposure` module now acts exclusively as an integration point for the *ExposureLayer*

#### API changes
Several API changes where introduced to streamline with *Android* and *HTML5* platforms.

## 0.2.0 to 0.72.0
Major changes introduced to modularize *Tech* and *Playback Context*.

#### Features as Components
Context sensitive playback with *Features as Components* introduces a clear, distinct per-tech playback experience. Typed error handling now takes place exclusively through the `onError` callback on `Player` and all *Exposure* integration has been moved to `ExposureContext`.

Constrained extensions on `Player` and the newly introduced `PlaybackTech` and `ExposureContext` protocol allows new features to be developed with strict tech targets in mind.

## Adopting 0.2.0
Please consult the [Installation](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master/README.md#installation) and [Usage](https://github.com/EricssonBroadcastServices/iOSClientExposure/blob/master/README.md#getting-started) guides for information about this initial release.
