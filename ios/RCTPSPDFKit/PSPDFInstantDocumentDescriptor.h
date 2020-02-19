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

/**
 Set this as `PSPDFInstantDocumentDescriptor.delayForSyncingLocalChanges` to disable automatic syncing of local changes.

 @note **Important:** When using this constant, remember to also disable listening for server changes to avoid nasty
 surprises! Instant’s sync operations are always two-way, so any incoming changes from the server would cause your local
 changes to be sent to the server.<br>
 If you are using `PSPDFInstantViewController`, that means you should set `shouldListenForServerChangesWhenVisible` to
 `NO`. If you are using your own custom `PSPDFViewController` subclass to display documents, you should refrain from
 using the `-[PSPDFInstantDocumentDescriptor startListeningForServerChanges]` API in such configurations. (As these calls
 need to be balanced, you really shouldn’t be calling `-[PSPDFInstantDocumentDescriptor stopListeningForServerChanges]`
 in that case either.)

 For more details on the sync cycle, refer to the documentation of `PSPDFInstantDocumentState`.
 */
PSPDF_EXPORT const NSTimeInterval PSPDFInstantSyncingLocalChangesDisabled;

/**
 Lists the observable states of an Instant document descriptor and its sync cycle.

 The term “sync cycle” refers to the repetitive transitions between the states “receiving changes” and “sending changes”
 until there are no unsynced local changes remaining, and the document becomes “clean”. If you are using automatic sync,
 a sync cycle will begin `PSPDFInstantDocumentDescriptor.delayForSyncingLocalChanges` seconds after the last change to
 an annotation in the document. When listening for server changes, a sync cycle can additionally be triggered by changes
 coming in from the server even before that interval has elapsed.<br>
 When not listening for server changes and with automatic sync of local changes disabled, a sync cycle starts whenever
 you call `-[PSPDFInstantDocumentDescriptor sync]`.

 `PSPDFInstantDidFinishSyncingNotification` is posted whenever a sync cycle completes successfully. If the cycle fails,
 `PSPDFInstantDidFailSyncingNotification` is posted instead.

 @note The states gathered and exposed in this enum have been preselected for relevance to an end user. If you find that
 you cannot provide the kind of feedback you need to the users of your app, please contact us via
 https://pspdfkit.com/support/request/
 */
typedef NS_CLOSED_ENUM(NSInteger, PSPDFInstantDocumentState) {
    /**
     The state of the document descriptor has not been determined yet.

     The state will be determined the first time you obtain a document from a downloaded document descriptor.
     */
    PSPDFInstantDocumentStateUnknown,
    /**
     The backing store of the document descriptor needs to be migrated before the descriptor becomes
     operational.
     */
    PSPDFInstantDocumentStateNeedsContentMigration,
    /**
     The backing store of the document descriptor is in the middle of a migration.

     It will most likely become operational later.
     */
    PSPDFInstantDocumentStateMigratingContent,
    /**
     The document descriptor does not have any local changes.

     If you are listening for server changes — as `PSPDFInstantViewController` does in its default configuration when
     visible — this also implies that you have the latest observable changes from the server.
     */
    PSPDFInstantDocumentStateClean,
    /**
     The document descriptor has local changes that have not been synced to the server.

     If you use automatic syncing, (either through `PSPDFInstantDocumentDescriptor.delayForSyncingLocalChanges` or by
     listening for server changes) your changes will be sent to the server during the next sync cycle. If you have
     disabled automatic syncing, calling `-[PSPDFInstantDocumentDescriptor sync]` will start a sync cycle to get all
     your local changes to the server and fetch the newest updates from it.
     */
    PSPDFInstantDocumentStateDirty,
    /**
     The document descriptor is busy syncing — currently sending its local changes to the server.

     Should communication with the server fail, the document descriptor will fall back into state “dirty”. If all goes
     well, it will transition to “receiving changes”.
     */
    PSPDFInstantDocumentStateSendingChanges,
    /**
     The document descriptor is busy syncing — currently receiving changes from the server.

     Should communication with the server fail the document descriptor will fall back into the “dirty” or “clean” state
     — depending on whether or not there are unsynced changes. If all goes well, it will transition to either the
     “clean” or the “sending changes” state — depending on whether new local changes have accumulated during the
     transmission.

     This repeated back and forth between the “sending changes” and “receiving changes” state is what we call the sync
     cycle. It starts when a sync request is made, and — if all goes well — ends when there are no local changes left.
     */
    PSPDFInstantDocumentStateReceivingChanges,
    /**
     The document descriptor is invalid and cannot be used any longer.

     You may want to remove its local storage, but that‘s about all you can do with it.
     */
    PSPDFInstantDocumentStateInvalid,
};

/**
 A `PSPDFInstantDocumentDescriptor` represents an editing context for annotations on a PDF file managed by Instant.

 The document descriptor allows you to download the file and synchronize the annotations in this context, while display
 and editing of the annotations happens via the specialized `PSPDFDocument` objects that it provides. You obtain
 instances that conform to this protocol from a `PSPDFInstantClient`, which also keeps the instances it creates alive.

 Instant manages the PDF files on disk efficiently, and will reuse the same file for all document descriptors with the
 same identifier. Therefore, there are some limitations to what you can do with the `PSPDFDocument` instances you obtain
 from a document descriptor. For details, see the documentation of `editableDocument`.

 ## Notifications
 A document descriptor posts the following notifications to inform you of relevant events:

 - `PSPDFInstantDidFailAuthenticationNotification` when authenticating the editing context failed
 - `PSPDFInstantDidFinishReauthenticationNotification` when the editing context has been reauthenticated
 - `PSPDFInstantDidFailReauthenticationNotification` when reauthenticating the editing context failed
 - `PSPDFInstantDidFinishDownloadNotification` when the download of the PDF file and associated annotations for a
   docment descriptor finishes
 - `PSPDFInstantDidFailDownloadNotification` when the download of the PDF file or the associated annotations for a
   document descriptor fails
 - `PSPDFInstantDidBeginSyncingNotification` when the document descriptor starts a new sync cycle
 - `PSPDFInstantSyncCycleDidChangeStateNotification` when the sync cycle changes its state
 - `PSPDFInstantDidFailSyncingNotification` when the sync cycle stops abnormally (reasons include cancellation)
 - `PSPDFInstantDidFinishSyncingNotification` when the sync cycle completes successfully

 Each of these notifications will typically be **posted on a background thread**, and have the document descriptor as
 their `object` property. For a centralized, more type-safe alternative see `PSPDFInstantClientDelegate`, and for more
 details on the sync cycle, refer to the documentation of `PSPDFInstantDocumentState`.
 */
PSPDF_AVAILABLE_DECL @protocol PSPDFInstantDocumentDescriptor <NSObject>

/**
 Uniquely identifies the PDF file backing this editing context.

 There can be multiple document descriptors that share the same  PDF file and therefore the same identifier. To uniquely
 identify a document descriptor, you have to take the `layerName` into account as well.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Name of the layer that specifies the annotations to use for this editing context.

 The name of the default layer is an empty string.
 */
@property (nonatomic, readonly) NSString *layerName;

/**
 Value encoded in the JWT used to authenticate the receiver.

 This property will be `nil` when you JWTs do not contain the `user_id` claim. It may also be `nil`, IFF you have
 downloaded the data with a version of Instant prior to the one bundled with PSPDFKit 7.6, and have not updated its JWT yet.
 */
@property (nonatomic, readonly, nullable) NSString *userID;

/**
 A Boolean value indicating whether the PDF file for this document descriptor has been downloaded from the server.
 */
@property (nonatomic, readonly, getter=isDownloaded) BOOL downloaded;

/**
 The current state of the document descriptor.

 @warning This property is not observable through KVO! Please listen to the notifications listed in this header or use
 `PSPDFInstantClientDelegate` instead.
 */
@property (nonatomic, readonly) PSPDFInstantDocumentState documentState;

/**
 Starts asynchronously downloading the PDF file and annotation data from PSPDFKit Server.

 When the download completes successfully, the `PSPDFInstantDidFinishDownloadNotification` will be posted. If it fails,
 `PSPDFInstantDidFailDownloadNotification` will be posted, containing the error in its user info dictionary.

 Should the PDF file and annotation data already be available locally, no download will be attempted. Instead this
 method with fail with `PSPDFInstantErrorAlreadyDownloaded`. If a download is already in progress but has not finished
 yet, this method will succeed without starting a duplicate download.

 This method will fail with `PSPDFInstantErrorInvalidJWT` if the value you passed cannot be decoded, or the decoded data
 relates to another layer. It will fail with `PSPDFInstantErrorUserIDMismatch` if the decoded user ID is incompatible
 with the receiver’s value.

 @param JWT A JWT that grants access to the layer represented by the receiver. This must be supplied by your own server.
 */
- (BOOL)downloadUsingJWT:(NSString *)JWT error:(NSError **)error;

/**
 The progress of the PDF and annotation download — may be used to cancel an in-progress download.

 This will be nil if when the PDF file and annotation have been downloaded.

 @note **Important:** The progress object should be considered read-only! Do not modify the `totalUnitCount`,
 `completedUnitCount`, `cancellationHandler` or other properties, and do not add any child progress objects.
 */
@property (atomic, readonly, nullable) NSProgress *downloadProgress;

/**
 Attempts to explicitly start the content migration for the given document descriptor.

 You can use this API to recover from `PSPDFInstantErrorContentMigrationNeeded` after a failed
 programmatic sync of the receiver. The migration is performed asynchronously.

 @note This call will fail with `PSPDFInstantErrorPerformingContentMigration` when a migration is
 already in progress.
 */
- (nullable NSProgress *)attemptContentMigration:(NSError **)error;

/**
 The progress of the active content migration — if any.

 In general, expect this to be `nil`.

 @note **Important:** The progress object should be considered read-only! Do not modify the `totalUnitCount`,
 `completedUnitCount`, `cancellationHandler` or other properties, and do not add any child progress objects.
 */
@property (atomic, readonly, nullable) NSProgress *migrationProgress;

/**
 Returns a PDF document, in which annotations may be edited.

 This returns an object even before the PDF and annotation data have been downloaded, so it can be set on a
 `PSPDFInstantViewController` immediately, which then shows the download progress. To start a download, use
 `-downloadUsingJWT:error:`.

 Some features of `PSPDFDocument` are not supported in documents managed by Instant:
 
 - Archiving with `NSCoding`: instead archive the JWT for the document descriptor’s `identifier` and `layerName`, and
 recreate the document by calling this method again.
 - Undo
 - Bookmarks
 - The document editor
 - Saving: only annotations may be modified, which are persisted automatically by Instant.

 There can only be a single editable document for a document descriptor at any time! Therefore, this method may return
 the same instance on repeated calls.
 If you need to display more than one instance of the same document at a time, for example when you want mirroring on an
 external screen, create secondary read-only instances using `-readOnlyDocument`.

 Objects returned by this method become invalid if the download fails, is cancelled, or when removing local storage
 for the document. In these cases the document instance may no longer be used. Since there can only be one editable
 document, you must release all references to the invalid document so it deallocates, then request a new one from this
 method.

 @warning **Instant uses a special annotation provider for its documents!** As a result the annotation manager of this
 document will not have a `fileAnnotationProvider`.
 */
@property (nonatomic, readonly) PSPDFDocument *editableDocument;

/**
 Returns a read-only PDF document for this editing context.

 There can only be a single editable Instant-enabled `PSPDFDocument` for a document descriptor at a time. But since one
 `PSPDFDocument` should only be used by one `PSPDFViewController`, there will be times — like mirroring on an external
 display — where you need more than just one. For these situations, you can get an arbitrary number of documents that
 are read-only:<br>
 When changes are made, these are updated as appropriate, but they will not allow you to make any edits — like adding,
 changing, or removing existing annotations.

 Otherwise this behaves the same as `editableDocument`.

 @warning **Instant uses a special annotation provider for its documents!** As a result the annotation manager of this
 document will not have a `fileAnnotationProvider`.
 */
- (PSPDFDocument *)readOnlyDocument;

/**
 Removes the annotation store from disk.

 Calling this method will also cancel any in-progress network operations for this document descriptor. Removing the
 annotation store may fail if the file-system operations fail.

 @warning This method must be called before authenticating the document descriptor as a different user. Providing an
 authentication token for a different user without calling this method first may raise an exception.
 */
- (BOOL)removeLocalStorageWithError:(NSError **)error;

/**
 Attempts to reauthenticate the receiver using the given JWT.

 Instant does not permanently store authentication information but it does cache it in memory. As a result, you will
 rarely have to call this method repeatedly on the same object during the a single run of your app. In particular, a
 freshly downloaded document descriptor is already authenticated — as downloading requires authentication.

 As a general rule, it is only necessary to call this method after
 `-[PSPDFInstantClientDelegate instantClient:documentDidFailAuthentication:]` has been called:<br>
 This will happen as soon as a sync operation fails due to an authentication error.

 You can, however, pro-actively call this method for every local document descriptor when your app starts. This may be
 useful to limit the number of requests that have to be made if, for example, you have stored the JWTs for your layers
 in the keychain, or your server backend provides an endpoint returning the JWTs for all of the layers a user may access
 in a single call.
 */
- (void)reauthenticateWithJWT:(NSString *)JWT;

#pragma mark - Uniquely Identifying Annotations

/**
 Returns the unique identifier for the given annotation of one of the receiver’s documents.

 You can use this method to — for example — associate data from arbitrary sources with annotations managed by Instant.
 Annotations created interactively by the user working on the `editableDocument` in a `PSPDFViewController` always have
 an identifier. If, however, you create a new annotation programmatically, the identifier will be available as soon as
 you add the annotation to the receiver’s `editableDocument`.<br>
 Identifiers returned from this method are guaranteed to be stable over time, and unique in the context of the document
 descriptor they belong to. Although they are typed as strings for interoperability, you should treat them as opaque
 objects. Due to deliberate design considerations on our part, they are URL-, XML-, and filesystem-safe.

 This method will fail if the annotation does not belong to any of the receiver’s documents. It may also fail if the
 receiver is no longer valid.

 @param annotation The annotation to identify.
 */
- (nullable NSString *)identifierForAnnotation:(PSPDFAnnotation *)annotation error:(NSError **)error;

/**
 Returns the annotation for the given identifer and document — if any.

 This method allows you to use values once returned from `-identifierForAnnotation:error:` for looking up annotations
 in a document managed by the receiver. As useful annotations are always related to a document, you have to specify
 which document that the annotation — if found — should belong to.<br>
 As such, calling this method will fail if the document you passed is not managed by the receiver, or if there is no
 annotation with the specified identifier. It will also fail if the document has not been dowloaded yet.

 @param identifier The unique identifier of the annotation to return.
 @param document The document to which the returned annotation — if any — belongs.
 */
- (nullable PSPDFAnnotation *)annotationWithIdentifier:(NSString *)identifier forDocument:(PSPDFDocument *)document error:(NSError **)error;

#pragma mark - Syncing Data

/**
 Syncs annotations with the PSPDFKit Server.

 When the PDF file and annotation data have been downloaded, this method initiates a one-time sync cycle:<br>
 Sync requests will be made until all local changes have been synced, until an error occurs, or until you call
 `-stopSyncing:`. If you are using `PSPDFInstantViewController` in its default configuration to display the document,
 there is no need to call this method. Instant will push edits to the server as they happen and will listen for changes
 from the server.

 This method allows you to sync a document descriptor that is not being displayed or for whose document(s) you have
 disabled automatic syncing. Automatic syncing is controlled by
 `PSPDFInstantViewController.shouldListenForServerChangesWhenVisible` and `delayForSyncingLocalChanges`.

 @note This method does nothing if the PDF file or annotations have not been downloaded yet.
 */
- (void)sync;

/**
 Stops the current sync cycle, optionally cancelling the current request.

 Calling this method is only necessary if you choose to sync manually. That is:

 - You have disabled `PSPDFInstantViewController.shouldListenForServerChangesWhenVisible` on every object showing one
   of the receiver’s documents,
 - you have set `delayForSyncingLocalChanges` on this object to `PSPDFInstantSyncingLocalChangesDisabled`,
 - you have balanced any call to `-startListeningForServerChanges` with a call to `-stopListeningForServerChanges`, and
 - you have called `sync`.

 If your answer to all of the above is yes, you may call this method to stop the current sync cycle. Passing `NO` will
 allow the current request to complete. This gives you the latest server state, but you may still have local changes
 that have not been synced.<br>
 Passing `YES` will cancel the current request immediately. Your view of the server’s state will most likely be outdated
 and if you had local changes, the server has probably not seen them yet.

 @param cancelCurrentRequest Whether the current request should be cancelled — even if it is receiving data.
 */
- (void)stopSyncing:(BOOL)cancelCurrentRequest;

/**
 Delay in seconds before kicking off automatic sync after local changes are made to the `editableDocument`’s annotations.

 If this is a positive value, Instant will automatically sync annotations with the PSPDFKit Server after annotations
 in the document are modified. Setting this to a higher value will reduce the load on the network and reduce energy
 use but means other users will not see annotation updates as soon, which also increases the chance of sync conflicts.
 Setting this to a positive value less than 1 second may strain the network and battery and is not recommended.

 Set this to `PSPDFInstantSyncingLocalChangesDisabled` to disable automatic syncing, in which case annotations must
 be synchronized manually by calling `sync`.

 Setting this to zero will not result in immediate syncing and is not supported. Attempting to sync immediately after
 every change would stress the network and be unlikely to result in faster syncing.

 Defaults to 1 second.
 */
@property (atomic) NSTimeInterval delayForSyncingLocalChanges;

/**
 Tells the receiver to start listening for changes from the server as they happen.

 Once a document descriptor’s data has been downloaded, you can use this method to begin observing the server for
 changes. The most common use case for this is that you are displaying the document in your custom PDF view controller,
 and you want to make sure that the user sees changes made on other devices in a real-time-like fashion.
 When you call this method, Instant will begin monitoring the server for changes until syncing fails, or until you
 call `-stopListeningForServerChanges` — whichever happens first.

 A word of warning:<br>
 Using the network, especially the cellular network, is one of the most energy intensive tasks. While we do our best to
 minimize the energy impact this feature has, if your app does not require (near-)real-time sync, consider using
 explicit user actions to call `sync` instead.

 @note If you use `PSPDFInstantViewController` you get this behavior for free! This method is provided if you cannot
 customize that class to suit your needs, but need real-time-like updates.
 */
- (void)startListeningForServerChanges;

/**
 Tells the receiver to stop listening for changes from the server.

 Once you are no longer interested in real-time updates from the server, use this method to stop listening for
 changes. A common scenario where you would want to call this, is when you stop displaying an Instant enabled document
 in your custom PDF view controller.

 @note If you use `PSPDFInstantViewController` you get this behavior for free! This method is provided if you cannot
 customize that class to suit your needs, but need real-time updates.
 */
- (void)stopListeningForServerChanges;

@end

#pragma mark - Notifications

/**
 Key for `NSNotification.userInfo` dictionary.

 Where supported, the value under this key will be an instance of `NSError`.
 */
PSPDF_EXPORT NSString *const PSPDFInstantErrorKey;

/**
 Key for `NSNotification.userInfo` dictionary.

 Where supported, the value under this key will be an instance of `NSString`.
 */
PSPDF_EXPORT NSString *const PSPDFInstantJWTKey;

/**
 Notification posted when downloading a PDF file from the server finishes.

 The object of this notification will be the `PSPDFInstantDocumentDescriptor` whose download completed.

 @note **Important:** This notification will be posted on a background thread.
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFinishDownloadNotification;

/**
 Notification posted when downloading the PDF file from the server fails.

 The object of this notification will be the `PSPDFInstantDocumentDescriptor` whose download failed.
 The error that occurred (`NSError`) is available under `PSPDFInstantErrorKey` in the `userInfo`.

 @note **Important:** This notification will be posted on a background thread.
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFailDownloadNotification;

/**
 Notification that is posted when a sync cycle begins.

 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that started syncing.
 A sync cycle ends with posting either a `PSPDFInstantDidFailSyncingNotification` in case an error occurs, or with a
 `PSPDFInstantDidFinishSyncingNotification` when all local changes have been synced successfully.<br>
 While the sync cycle is running, any number of `PSPDFInstantSyncCycleDidChangeStateNotification`s can be posted.

 For more details on the sync cycle, refer to the documentation of `PSPDFInstantDocumentState`.

 @note **Important:** This notification will be posted on a background thread.
 @see `PSPDFInstantSyncCycleDidChangeStateNotification`<br>
 `PSPDFInstantDidFailSyncingNotification`<br>
 `PSPDFInstantDidFinishSyncingNotification`<br>
 `PSPDFInstantDocumentState`
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidBeginSyncingNotification;

/**
 Notification that is posted when a sync cycle changes its state.

 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that changed its sync state. Any number of
 these notifications can be posted while the sync cycle is running.

 For more details on the sync cycle, refer to the documentation of `PSPDFInstantDocumentState`.

 @note **Important:** This notification will be posted on a background thread.
 @see `PSPDFInstantDidBeginSyncingNotification`<br>
 `PSPDFInstantDidFailSyncingNotification`<br>
 `PSPDFInstantDidFinishSyncingNotification`<br>
 `PSPDFInstantDocumentState`
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantSyncCycleDidChangeStateNotification;

/**
 Notification that is posted when a sync cycle completes with an error.

 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that failed synchronization.
 The error that occurred (`NSError`) is available under `PSPDFInstantErrorKey` in the `userInfo`.

 @note **Important:** This notification will be posted on a background thread.
 @see `PSPDFInstantDidBeginSyncingNotification`<br>
 `PSPDFInstantSyncCycleDidChangeStateNotification`<br>
 `PSPDFInstantDidFinishSyncingNotification`<br>
 `PSPDFInstantDocumentState`
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFailSyncingNotification;

/**
 Notification that is posted when a sync cycle completes successfully.

 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that has been synced.

 For more details on the sync cycle, refer to the documentation of `PSPDFInstantDocumentState`.

 @note **Important:** This notification will be posted on a background thread.
 @see `PSPDFInstantDidBeginSyncingNotification`<br>
 `PSPDFInstantSyncCycleDidChangeStateNotification`<br>
 `PSPDFInstantDidFailSyncingNotification`<br>
 `PSPDFInstantDocumentState`
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFinishSyncingNotification;

/**
 Notification posted when Instant fails to authenticate with the PSPDFKit Server to synchronize annotations.

 This notification typically means that the user no longer has access to the document or that the JWT expired. You
 should ask your backend server for a new JWT for this document identifier and, if the user should still be allowed to
 access that document, pass the new JWT into `-[PSPDFInstantDocumentDescriptor reauthenticateWithJWT:]`. If your
 backend server decided that the user no longer has access, stop showing this document to the user and call
 `-[PSPDFInstantDocumentDescriptor removeLocalStorageWithError:]` instead.
 
 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that could not be authenticated.

 @note **Important:** This notification will be posted on a background thread.
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFailAuthenticationNotification;

/**
 Notification posted when the authentication token for a document has been successfully updated.
 
 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that has been reauthenticated. The
 accepted JWT is available as an `NSString` under `PSPDFInstantJWTKey` in the notification’s `userInfo`.

 @note **Important:** This notification will be posted on a background thread.
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFinishReauthenticationNotification;

/**
 Notification posted when the authentication token for a document could not be updated.
 
 The object of this notification will be the `PSPDFInstantDocumentDescriptor` that could not be reauthenticated. The
 error that occurred is available under `PSPDFInstantErrorKey` in the notification’s `userInfo`.

 @note **Important:** This notification will be posted on a background thread.
 */
PSPDF_EXPORT NSNotificationName const PSPDFInstantDidFailReauthenticationNotification;

NS_ASSUME_NONNULL_END
