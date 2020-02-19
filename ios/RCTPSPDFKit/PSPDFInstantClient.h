//
//  Copyright © 2017-2020 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <Foundation/Foundation.h>
#import <PSPDFKit/PSPDFKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PSPDFInstantClientDelegate, PSPDFInstantDocumentCacheEntry, PSPDFInstantDocumentDescriptor;

/**
 The entry point to Instant, representing a client that can connect to PSPDFKit Server.

 The Instant client manages the descriptors of the documents that you have access to. It provides the container for your
 downloaded documents, and controls the communication channel to the server. By providing a delegate, you are informed
 of relevant events regarding the synced documents and can manage tasks like authentication in a centralized manner.
 */
PSPDF_CLASS_AVAILABLE @interface PSPDFInstantClient : NSObject

/**
 The URL of the directory where Instant stores its documents, which is a subdirectory of Application Support.

 This may be used to set a data protection class for all Instant data  as described in
 https://pspdfkit.com/guides/ios/current/instant/data-protection/ . It is possible to customize the directory by
 subclassing and overriding this method, but there should typically be no need to do so.

 @warning The internal structure of this directory is private!
 */
@property (class, nonatomic, readonly) NSURL *dataDirectory;

PSPDF_EMPTY_INIT_UNAVAILABLE

/**
 Initializes a new client object.

 Creating a new client object requires reading from, and potentially writing to permanent storage. There are a several
 scenarios where these operations can fail: running out of space, insufficient permissions, data corruption are just
 some of those.

 As such it is important that you appropriately handle the `PSPDFInstantError` in case of a failure.

 @param serverURL The base URL of the PSPDFKit Server the client should connect to.
 @param error A pointer to be populated with an error when creating the client failed.
 @return The newly created client.
 */
- (nullable instancetype)initWithServerURL:(NSURL *)serverURL error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/**
 The base URL of the PSPDFKit Server the client connects to, as provided when creating the client;
 */
@property (nonatomic, readonly) NSURL *serverURL;

/**
 An object to be notified of download and authentication events for documents managed by this client.

 All delegate methods will be called on a background thread.
 */
@property (nonatomic, weak) id<PSPDFInstantClientDelegate> delegate;

/// @group Obtaining Document Descriptors

/**
 Convenience that extracts the layer information from the given JWT.

 Extracts the document identifier and layer name from the passed JWT, ignoring the expiration date, and returns a
 document descriptor for the layer information. The receiver will keep a reference to the returned object and return the
 same instance for repeated calls with JWTs containing the same layer information.

 If the JWT is in an invalid format, this method fails. If the layer information could be extracted, the call will
 immediately return a document descriptor — regardless of the JWTs actual fitness. Validation of the JWTs signature and
 expiration date is performed asynchronously when you actually attempt to sync the returned object.

 @param JWT A JSON web token returned by your backend, identifying the document and layer you want to access.
 @param error A pointer to be populated with an error when this call fails.
 */
- (nullable id<PSPDFInstantDocumentDescriptor>)documentDescriptorForJWT:(NSString *)JWT error:(NSError **)error;

/**
 Returns all locally available document descriptors, grouped by document identifier.

 This method gives you convenient access to the document descriptors for all locally available layers of all downloaded
 documents. Each key in the returned dictionary corresponds to the identifier of a downloaded document. As there is no
 inherent order to the layers that exist for any given document, the corresponding value is a set (rather than an array)
 of document descriptors for those layers.

 @note It is possible that a document is locally available, but we have no layers for it anymore. In those cases, the
 document identifier **will not** be contained in the dictionary. In effect, the dictionary will be empty if there are
 only documents left that have no local layers anymore.
 */
- (nullable NSDictionary<NSString *, NSSet<id<PSPDFInstantDocumentDescriptor>> *> *)localDocumentDescriptors:(NSError **)error;

/// @group Accessing the Disk Cache

/**
 Purges any cache entries where we have a document, but no annotations available.

 Because there can be multiple layers for just a single document, removing the local data of a document descriptor only
 purges its annotation data from disk. The lion’s share of the disk space required by a document descriptor, however, is
 the actual PDF file. This can lead to the situation where an instant client still occupies a lot of disk space for its
 cache, even though most of the data it holds is no longer referenced. We call those file for which no layers are loaded
 “unreferenced”.

 This method uses file coordination to safely and atomically identify all unreferenced files, and purges them from disk.
 You can call it occasionally during app startup, or at any other point in time when you want to reclaim unneeded disk
 space.

 @note This method is **not** equivalent to calling `removeLocalStorageForDocumentIdentifier:error:` for any entry
 returned from `listCacheEntries:` where the `downloadedLayerNames` is empty. You can think of it as wrapping all those
 calls into one atomic transaction, though.

 @param error A pointer to be populated in case of an error, detailing why the operation failed.
 @return On success, the (possibly empty) list of identifiers of all the documents that have been purged.
 */
- (nullable NSSet<NSString *> *)removeUnreferencedCacheEntries:(NSError **)error;

/**
 Returns a snapshot of the current state of the document disk cache.

 This method allows you to inspect how much disk space is currently occupied by the receiver, and decide what you might
 want to purge in orded to reclaim additional space.

 @note For ease of use, this method returns just a snapshot of the current state. In practice, this should not be an
 issue because the lion’s share of the space occupied by a document is the actual PDF file — and that remains untouched,
 no matter how many annotations you add to whichever layers.

 @return A (possibly empty) snapshot of the disk cache metadata, or `nil` if the disk cache could not be queried.
 */
- (nullable NSSet<id<PSPDFInstantDocumentCacheEntry>> *)listCacheEntries:(NSError **)error;

/**
 Removes the local data for the given document identifier, invalidating any associated document descriptors.

 In order to reclaim disk space, you may want to prune the cache from time to time. If purging the data for unreferenced
 files is not enough, this method allows you to selectively remove all on-disk data associated with a given document
 identifier — regardless of that data still being referenced.

 When called, this method attempts to query the disk cache, and invalidates any related existing document descriptor. It
 then purges all the associated data from disk. The method will fail with a `PSPDFInstantErrorCouldNotReadFromDiskCache`
 if the disk cache cannot be queried, or with a `PSPDFInstantErrorCouldNotRemoveDiskCacheEntries` if the data could not
 be deleted.

 @param documentIdentifier The identifier for the document whose cache entry should be removed from disk.
 @param error A pointer to be populated when this method fails.
 */
- (BOOL)removeLocalStorageForDocumentIdentifier:(NSString *)documentIdentifier error:(NSError **)error;

/**
 Removes the client’s local storage from disk, including storage for all documents.
 This will also cancel any in-progress network operations for all the client’s documents.

 If your app has a sign out procedure, this method should be called when a user signs out.

 Errors may occur due to file system operations failing.
 */
- (BOOL)removeLocalStorageWithError:(NSError **)error;

@end

#pragma mark -

/**
 The delegate of a `PSPDFInstantClient` must adopt this protocol to be notified of download and authentication events.

 Delegates that are interested in events around the sync cycle can also implement the optional methods listed in the
 “Sync Events” section. For a more detailed explanation of the sync cycle of a document and its possible states, please
 refer to the documentation on `PSPDFInstantDocumentState`.
 
 If you need multiple observers or are only interested in the events of a single document, you can use the notifications
 posted by `PSPDFInstantDocumentDescriptor`.

 @note **Important:** All methods in this protocol will be called on a background thread!
 */
PSPDF_AVAILABLE_DECL @protocol PSPDFInstantClientDelegate <NSObject>

#pragma mark Download Events

/**
 Called when downloading a PDF file from the server finishes.

 At this point the instances returned by `PSPDFInstantDocumentDescriptor.editableDocument` or
 `-[PSPDFInstantDocumentDescriptor readOnlyDocument]` of this document descriptor will be fully usable.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document whose download finished.
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient didFinishDownloadForDocumentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor;

/**
 Called when downloading a PDF file from the server fails.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document whose download failed.
 @param error The error that occurred.
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient documentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor didFailDownloadWithError:(NSError *)error;

#pragma mark Authentication Events

/**
 Called when the document fails to authenticate with the PSPDFKit Server to synchronize annotations.

 This typically means either the user no longer has access to the document or the JWT expired. Your own server should be
 able to say if the user still has access.

 If the user still has access, obtain a new JWT from your server and call
 `-[PSPDFInstantDocumentDescriptor reauthenticateWithJWT:]` on the document descriptor. If the user no longer has
 access, consider stopping showing this document to the user and call
 `-[PSPDFInstantDocumentDescriptor removeLocalStorageWithError:]` on the document descriptor.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document that failed authentication.
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient didFailAuthenticationForDocumentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor;

/**
 Called when a prior call to `-[PSPDFInstantDocumentDescriptor reauthenticateWithJWT:]` has completed successfully.

 The JWT that you passed into that method and which has been accepted is relayed back to you. The token would be safe to
 persist so that you can re-use it the next time your app launches.

 @param instantClient The sender of the message.
 @param validJWT The JWT that has been used to authenticate the document.
 @param documentDescriptor The descriptor of the document that has been reauthenticated.
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient documentDescriptor:(id <PSPDFInstantDocumentDescriptor>)documentDescriptor didFinishReauthenticationWithJWT:(NSString *)validJWT;

/**
 Called when a prior call to `-[PSPDFInstantDocumentDescriptor reauthenticateWithJWT:]` has failed.

 If authentication failed for any other reasons than a dropped connection and you chose to store a JWT for this document
 descriptor, you should delete the JWT when receiving this message.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document that could not be reauthenticated.
 @param error The an error detailing why reauthentication failed.
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient documentDescriptor:(id <PSPDFInstantDocumentDescriptor>)documentDescriptor didFailReauthenticationWithError:(NSError *)error;

#pragma mark Sync Events

@optional

/**
 Called when the document begins a new sync cycle.

 When listening for server changes, a sync cycle begins when changes from the server start coming in. Otherwise, a sync
 cycle begins when you call `-[PSPDFInstantDocumentDescriptor sync]` on an object that isn’t already syncing, or because
 of automatic sync of changes.<br>
 For more details on the sync cycle, please refer to the documentation of `PSPDFInstantDocumentState`.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document that has begun a new sync cycle.
 @see `-instantClient:didChangeSyncStateForDocumentDescriptor:`<br>
 `-instantClient:documentDescriptor:didFailSyncWithError:`<br>
 `-instantClient:didFinishSyncForDocumentDescriptor:`<br>
 `PSPDFInstantDocumentState`
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient didBeginSyncForDocumentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor;

/**
 Called when the document changes its sync state.

 After `-instantClient:didBeginSyncForDocumentDescriptor:`, this method may be called multiple times during the sync cycle. The
 cycle continues until either `-instantClient:didFinishSyncForDocumentDescriptor:` or
 `-instantClient:documentDescriptor:didFailSyncWithError:` is called.<br>
 For more details on the sync cycle, please refer to the documentation of `PSPDFInstantDocumentState`.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document that changed its sync state.
 @see `-instantClient:didBeginSyncForDocumentDescriptor:`<br>
 `-instantClient:documentDescriptor:didFailSyncWithError:`<br>
 `-instantClient:didFinishSyncForDocumentDescriptor:`<br>
 `PSPDFInstantDocumentState`
 */
- (void)instantClient:(PSPDFInstantClient *)instantClient didChangeSyncStateForDocumentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor;

/**
 Called when the sync cycle completes with an error.

 The most likely reason is network failure. Other common reasons are expiration of your authentication token, and
 cancellation.<br>
 For more details on the sync cycle, please refer to the documentation of `PSPDFInstantDocumentState`.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document that failed synchronization.
 @param error The error that occurred.
 @see `-instantClient:didBeginSyncForDocumentDescriptor:`<br>
 `-instantClient:didChangeSyncStateForDocumentDescriptor:`<br>
 `-instantClient:didFinishSyncForDocumentDescriptor:`<br>
 `PSPDFInstantDocumentState`
*/
- (void)instantClient:(PSPDFInstantClient *)instantClient documentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor didFailSyncWithError:(NSError *)error;

/**
 Called when a sync cycle completes successfully.

 A sync cycle finishes when there are no local changes left at the end of a sync operation.<br>
 For more details on the sync cycle, please refer to the documentation of `PSPDFInstantDocumentState`.

 @param instantClient The sender of the message.
 @param documentDescriptor The descriptor of the document that finished synchronization.
 @see `-instantClient:didBeginSyncForDocumentDescriptor:`<br>
 `-instantClient:didChangeSyncStateForDocumentDescriptor:`<br>
 `-instantClient:documentDescriptor:didFailSyncWithError:`<br>
 `PSPDFInstantDocumentState`
*/
- (void)instantClient:(PSPDFInstantClient *)instantClient didFinishSyncForDocumentDescriptor:(id<PSPDFInstantDocumentDescriptor>)documentDescriptor;

@end

NS_ASSUME_NONNULL_END
