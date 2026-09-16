//
//  PhotoLibraryService.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import Photos
import UIKit

final class PhotoLibraryService {
    
    private let imageManager = PHImageManager.default()
    
    
    // MARK: - Permission
    
    func requestPermission() async -> PHAuthorizationStatus {
        
        await PHPhotoLibrary.requestAuthorization(
            for: .readWrite
        )
    }
    
    
    func currentPermission() -> PHAuthorizationStatus {
        
        PHPhotoLibrary.authorizationStatus(
            for: .readWrite
        )
    }
    
    
    // MARK: - Fetch Screenshots
    
    func fetchLatestScreenshots(
        limit: Int = 20
    ) async -> [Track] {
        
        let options = PHFetchOptions()
        
        // Newest screenshot first
        options.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: false
            )
        ]
        
        let assets = PHAsset.fetchAssets(
            with: .image,
            options: options
        )
        
        var tracks: [Track] = []
        
        
        for index in 0..<assets.count {
            
            let asset = assets.object(at: index)
            
            // Only screenshot images
            guard asset.mediaSubtypes.contains(.photoScreenshot)
            else {
                continue
            }
            
            guard let image = await loadImage(
                from: asset
            ) else {
                continue
            }
            
            let track = Track(
                id: asset.localIdentifier,
                image: image,
                createdAt: asset.creationDate ?? Date(),
                title: nil,
                rediscoveryDescription: nil,
                detailDescription: nil,
                tags: [],
                category: nil
            )
            
            tracks.append(track)
            
            if tracks.count == limit {
                break
            }
        }
        
        return tracks
    }
    
    
    // MARK: - Load Image
    
    private func loadImage(
        from asset: PHAsset
    ) async -> UIImage? {
        
        await withCheckedContinuation { continuation in
            
            let options = PHImageRequestOptions()
            
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(
                    width: 500,
                    height: 1000
                ),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                
                continuation.resume(
                    returning: image
                )
            }
        }
    }
}
