

# Download

## Download with AVAssetDownloadTask (iOS 10+) -- FairPlay or Clear HLS

Call `LocalAssetsManager.prepareForDownload(of:)`.
Returns: 
- AVURLAsset optionally configured with the PlayKit's FairPlay license acquisition delegate (AVAssetResourceLoaderDelegate)
- PKMediaSource: the selected MediaSource

The application is responsible for starting and managing AVAssetDownloadTask and related APIs. PlayKit is only responsible for the FairPlay license delegate.

## Download with DTG - HLS only

### Clear: iOS 8+

Call `LocalAssetsManager.getPreferredDownloadableMediaSource(for:)`, returns a PKMediaSource recommended for download.
Pass the `PKMediaSource.contentUrl` property to DTG.

### FairPlay: iOS 10.3+

Same as clear. In addition, when download is finished, call `LocalAssetsManager.registerDownloadedAsset(location:mediaSource:callback:)`.

# Playback

Call `LocalAssetsManager.createLocalMediaEntry(for:localURL:)`, returns a PKMediaEntry ready to play.


