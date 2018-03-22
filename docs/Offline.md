

# Download

## Download with AVAssetDownloadTask (iOS 10+) -- FairPlay or Clear

Call `LocalAssetsManager.prepareForDownload(of:)`.
Returns: 
- AVURLAsset configured with the FairPlay AssetResourceLoader delegate (if required)
- PKMediaSource: the selected MediaSource

The application is responsible for using AVAssetDownloadTask


## Download with DTG

### Clear: iOS 8+

Call `LocalAssetsManager.getPreferredDownloadableMediaSource(for:)`.
Returns a PKMediaSource recommended for download.
Pass the `PKMediaSource.contentUrl` property to DTG.

### FairPlay: iOS 10.3+

Same as clear. In addition, when download is finished, call `LocalAssetsManager.registerDownloadedAsset(location:mediaSource:callback:)`.

# Playback

Call `LocalAssetsManager.createLocalMediaEntry(for:localURL:)`.
Returns a PKMediaEntry ready to play.


