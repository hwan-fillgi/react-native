//
//  Copyright © 2017-2020 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <PSPDFKit/PSPDFEnvironment.h>

NS_ASSUME_NONNULL_BEGIN
/**
 A snapshot of the disk cache entry for a certain document identifier.

 Keeping these objects around after their creation does not do any harm. As snapshots, however, they **do not** track
 changes to the disk cache over time. Because the `overallDiskSpace` is typically dominated by the size of the PDF — not
 the annotation data stored in any layer — its order of magnitude should be fairly stable, though. Notable exceptions
 would be scratch-pad style documents that contain mostly empty pages, or documents with many layers containing loads
 of annotations each.
 */
PSPDF_AVAILABLE_DECL @protocol PSPDFInstantDocumentCacheEntry <NSObject>

/// The document identifier corresponding to this cache entry.
@property (nonatomic, readonly) NSString *documentIdentifier;

/// The disk space (in bytes) occupied by the document and all its downloaded layers.
@property (nonatomic, readonly) unsigned long long overallDiskSpace;

/// The names of all downloaded layers — may be empty!
@property (nonatomic, readonly) NSSet<NSString *> *downloadedLayerNames;

/// Bitmask for diagnostics of a cache entry.
typedef NS_OPTIONS(NSUInteger, PSPDFInstantCacheEntryState) {
    /// The cache entry has been corrupted and _needs to_ be purged: it cannot produce usable document descriptors!
    PSPDFInstantCacheEntryStateCorrupted = 1 << 0,

    /**
     The cache entry is valid but has no loaded layers.

     In order to reclaim unneeded disk space, it _should be_ purged when the opportunity arises.
     */
    PSPDFInstantCacheEntryStateUnreferenced = 1 << 1,

    /**
     Retrieving metadata for a certain layer failed.

     Whether or not this entry should be purged depends on the “corrupted” flag. This flag should only be set rarely, if
     ever! Should you see this happen on a regular basis, please report a bug with steps how to reproduce this.
     */
    PSPDFInstantCacheEntryStateLayerAbsurdity = 1 << 2,
};

/// Diagnostic information about the receiver.
@property (nonatomic, readonly) PSPDFInstantCacheEntryState entryState;

@end
NS_ASSUME_NONNULL_END
