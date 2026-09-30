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

    func fetchLatestScreenshots(
        limit: Int = 20
    ) async -> [Track] {

        let options =
            PHFetchOptions()

        options.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: false
            )
        ]


        let assets =
            PHAsset.fetchAssets(
                with: .image,
                options: options
            )


        var tracks: [Track] = []


        for index in 0..<assets.count {

            let asset =
                assets.object(
                    at: index
                )


            guard asset
                .mediaSubtypes
                .contains(
                    .photoScreenshot
                )
            else {
                continue
            }


            guard let image =
                await loadImage(
                    assetID:
                        asset.localIdentifier
                )
            else {
                continue
            }


            let track =
                Track(
                    id:
                        asset.localIdentifier,

                    image:
                        image,

                    createdAt:
                        asset.creationDate
                        ?? Date(),

                    title:
                        nil,

                    rediscoveryDescription:
                        nil,

                    detailDescription:
                        nil,

                    tags:
                        [],

                    categoryName:
                        nil
                )


            // Add screenshot to result
            tracks.append(track)


            // Stop after reaching limit
            if tracks.count >= limit {
                break
            }
        }


        // IMPORTANT:
        // Return after the loop
        return tracks
    }


    // MARK: - Get ALL Screenshot IDs

    func fetchAllScreenshotInfos()
    async -> [ScreenshotAssetInfo] {

        let options =
            PHFetchOptions()


        options.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: false
            )
        ]


        let assets =
            PHAsset.fetchAssets(
                with: .image,
                options: options
            )


        var screenshots:
            [ScreenshotAssetInfo] = []


        for index in 0..<assets.count {

            let asset =
                assets.object(
                    at: index
                )


            guard asset
                .mediaSubtypes
                .contains(
                    .photoScreenshot
                )
            else {
                continue
            }


            screenshots.append(
                ScreenshotAssetInfo(
                    id:
                        asset.localIdentifier,

                    createdAt:
                        asset.creationDate
                        ?? Date()
                )
            )
        }


        return screenshots
    }


    // MARK: - Load One Image

    func loadImage(
        assetID: String
    ) async -> UIImage? {

        let result =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetID
                ],
                options: nil
            )


        guard let asset =
            result.firstObject
        else {
            return nil
        }


        return await withCheckedContinuation {
            continuation in

            let options =
                PHImageRequestOptions()


            options.deliveryMode =
                .highQualityFormat

            options.resizeMode =
                .fast

            options.isNetworkAccessAllowed =
                true


            imageManager.requestImage(
                for: asset,

                targetSize:
                    CGSize(
                        width: 900,
                        height: 1800
                    ),

                contentMode:
                    .aspectFit,

                options:
                    options

            ) { image, info in

                let isDegraded =
                    (
                        info?[
                            PHImageResultIsDegradedKey
                        ] as? Bool
                    ) ?? false


                if !isDegraded {

                    continuation.resume(
                        returning: image
                    )
                }
            }
        }
    }
}
