//
//  PhotoLibraryService.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import Photos
import UIKit

final class PhotoLibraryService {

    private let imageManager =
        PHImageManager.default()


    // MARK: - Permission

    func requestPermission()
    async -> PHAuthorizationStatus {

        await PHPhotoLibrary
            .requestAuthorization(
                for: .readWrite
            )
    }


    func currentPermission()
    -> PHAuthorizationStatus {

        PHPhotoLibrary
            .authorizationStatus(
                for: .readWrite
            )
    }


    // MARK: - Latest Screenshots For UI

    func fetchLatestScreenshots(limit: Int = 20) async -> [Track] {
        let metadata = await fetchAllScreenshotInfos(limit: limit)
        var tracks: [Track] = []
        for item in metadata {
            guard !Task.isCancelled else { break }
            let image = await loadImage(assetID: item.id)
            tracks.append(Track(id: item.id, image: image, createdAt: item.createdAt))
        }
        return tracks
    }

    // MARK: - Get ALL Screenshot IDs

    func fetchAllScreenshotInfos(scope: ProcessingScope = .allUnprocessed, limit: Int? = nil) async -> [ScreenshotAssetInfo] {
        let fetch = Task.detached(priority: .userInitiated) {
            let options = PHFetchOptions()
            if let limit { options.fetchLimit = max(0, limit) }
            var predicates = [NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)]
            if let interval = scope.interval() {
                predicates.append(NSPredicate(format: "creationDate >= %@ AND creationDate < %@", interval.start as NSDate, interval.end as NSDate))
            }
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(with: .image, options: options)
            var result: [ScreenshotAssetInfo] = []
            assets.enumerateObjects { asset, _, stop in
                if Task.isCancelled { stop.pointee = true; return }
                result.append(ScreenshotAssetInfo(id: asset.localIdentifier, createdAt: asset.creationDate ?? .distantPast, hasCreationDate: asset.creationDate != nil))
            }
            return result
        }
        return await withTaskCancellationHandler { await fetch.value } onCancel: { fetch.cancel() }
    }


    // MARK: - Load One Image

    func loadImage(assetID: String, forAnalysis: Bool = false) async -> UIImage? {
        let request = CancellablePhotoRequest()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                request.start(assetID: assetID, forAnalysis: forAnalysis, continuation: continuation)
            }
        } onCancel: { request.cancel() }
    }
}

// Owns exactly one Photos request. Cancellation and completion may race.
nonisolated private final class CancellablePhotoRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<UIImage?, Never>?
    private var requestID: PHImageRequestID?
    private var finished = false

    func start(assetID: String, forAnalysis: Bool, continuation: CheckedContinuation<UIImage?, Never>) {
        lock.lock()
        if finished { lock.unlock(); continuation.resume(returning: nil); return }
        self.continuation = continuation
        lock.unlock()
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
            guard let asset = assets.firstObject else { self.finish(nil); return }
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = !forAnalysis
            let id = PHImageManager.default().requestImage(for: asset,
                targetSize: CGSize(width: forAnalysis ? ProcessingPolicy.imageWidth : 900, height: forAnalysis ? ProcessingPolicy.imageHeight : 1800),
                contentMode: .aspectFit, options: options) { image, info in
                    if (info?[PHImageResultIsDegradedKey] as? Bool) != true { self.finish(image) }
                }
            self.lock.lock()
            self.requestID = id
            let alreadyFinished = self.finished
            self.lock.unlock()
            if alreadyFinished { PHImageManager.default().cancelImageRequest(id) }
            DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in self?.cancel() }
        }
    }

    private func finish(_ image: UIImage?) {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finished = true
        let callback = continuation
        continuation = nil
        lock.unlock()
        callback?.resume(returning: image)
    }

    func cancel() {
        finish(nil)
        lock.lock()
        let id = requestID
        lock.unlock()
        if let id { PHImageManager.default().cancelImageRequest(id) }
    }
}
