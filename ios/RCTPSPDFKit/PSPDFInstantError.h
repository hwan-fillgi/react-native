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

/// Domain for errors encountered by PSPDFKit Instant.
PSPDF_EXPORT NSErrorDomain const PSPDFInstantErrorDomain;

/**
 Possible error codes in the `PSPDFInstantErrorDomain`.
 */
typedef NS_ERROR_ENUM(PSPDFInstantErrorDomain, PSPDFInstantError) {
    /// The error is unknown to Instant. The underlying error will be placed in `NSUnderlyingErrorKey` in the `userInfo`.
    PSPDFInstantErrorUnknown = 1,

    /**
     The feature you were trying to use is not supported in the context of Instant.

     This will, for example, happen when you call `-[PSPDFDocument saveWithOptions:error:]` on documents managed by Instant.
     */
    PSPDFInstantErrorFeatureUnsupported = 2,

    /// The document that you were trying to operate on is invalid or unknown to Instant.
    PSPDFInstantErrorInvalidDocument = 3,

    /**
     The JWT you provided to authenticate has been rejected.

     This error code is relevant when you are attempting to reauthenticate a document descriptor:<br>
     Since the access to a document can be revoked at any time, it is possible that even a freshly obtained JWT is
     rejected by PSPDFKit Server when you try to reauthenticate that document descriptor. When this happens,
     `-[PSPDFInstantClientDelegate instantClient:documentDescriptor:didFailReauthenticationWithError:]` will be
     called with this error code on `PSPDFInstantClient.delegate`.

     @note The layer’s backing storage will not be removed from disk! You can still access and modify that descriptor’s
     `editableDocument`. Any changes you make to it will, however, not be synced anymore until the descriptor has been
     successfully reauthenticated.
     */
    PSPDFInstantErrorAccessDenied = 4,

    /// Error indicating an attempt was made to download a document that has already been downloaded. The error will have a document descriptor under `PSPDFInstantErrorDocumentDescriptorKey` in the user info.
    PSPDFInstantErrorAlreadyDownloaded = 5,

    /**
     Reading from or writing to the annotation database failed.

     Whenever possible, the SQLite (extended) error code can be found under the user info key
     `PSPDFInstantErrorSQLiteExtendedErrorCodeKey` as an `NSNumber`.
     */
    PSPDFInstantErrorDatabaseAccessFailed = 6,

    /**
     Writing a PDF or metadata file to disk failed.

     @note This does not refer to database errors: Those will be reported with `PSPDFInstantErrorDatabaseAccessFailed`,
     with an appropriate SQLite extended error code.<br>
     Instead, this error code is relevant for downloading documents.
     */
    PSPDFInstantErrorCouldNotWriteToDisk = 7,

    /// The URL you have used is invalid for this purpose.
    PSPDFInstantErrorInvalidURL = 8,

    /// Error returned when an attempt is made to save a document managed by Instant. The error will have a document under `PSPDFInstantErrorDocumentKey` in the user info.
    PSPDFInstantErrorSavingDisabled = 9,

    /// Error returned when the document passed into `-[PSPDFInstantDocumentDescriptor annotationWithIdentifier:forDocument:error]` is not managed by the receiver.
    PSPDFInstantErrorUnmanagedDocument = 10,

    /// Error returned when the receiver does not know of an annotation for the identifier passed into `-[PSPDFInstantDocumentDescriptor annotationWithIdentifier:forDocument:error]`.
    PSPDFInstantErrorNoSuchAnnotation = 11,

    /// Error returned when the annotation passed into `-[PSPDFInstantDocumentDescriptor identifierForAnnotation:error:]` is not managed by the receiver.
    PSPDFInstantErrorUnmanagedAnnotation = 12,

    /**
     Retrieving an item from the disk cache failed.

     This can happen if the disk cache is modified by other means than Instant’s public API. Although less likely, this
     can also be caused by a defect of the disk itself.
     */
    PSPDFInstantErrorCouldNotReadFromDiskCache = 13,

    /**
     Removing an item from the disk cache filed.

     This can happen if the disk cache is modified by other means than Instant’s public API. Although less likely, this
     can also be caused by a defect of the disk itself.
     */
    PSPDFInstantErrorCouldNotRemoveDiskCacheEntries = 14,

    /**
     The operation could not be completed because the network request failed. This happens when offline.

     If you were syncing manually, retry at a later date. If you are using automatic synchronization via
     `PSPDFInstantDocumentDescriptor.delayForSyncingLocalChanges`,
     `-[PSPDFInstantDocumentDescriptor startListeningForServerChanges]`, or
     `PSPDFInstantViewController.shouldListenForServerChangesWhenVisible`, there is not much for you to do: a re-attempt
     to sync will be scheduled at an appropriate time.<br>
     However, you may still want to inform your users, that their local changes are not synced, though.
     */
    PSPDFInstantErrorRequestFailed = 16,

    /**
     The operation could not be completed because the server sent invalid data.
     
     If you ever see this error, please [contact support](https://pspdfkit.com/support/request).
     */
    PSPDFInstantErrorInvalidServerData = 17,

    /**
     The operation could not be completed because the server rejected the request as invalid.

     If you ever see this error, please [contact support](https://pspdfkit.com/support/request).
     */
    PSPDFInstantErrorInvalidRequest = 18,

    /**
     The operation could not be completed because the client and server have incompatible versions: the server expects a newer client.

     You need to update this framework in your app to a compatible version and release an update.
     If a user sees this on their device they need to update your app.

     In the default setting, `PSPDFInstantViewController.shouldShowCriticalErrors` causes an alert to be shown to the
     user when this error is encountered, saying that an app update is needed.<br>
     If you have your own error handling for this situation you can safely set that property to `NO`.
     */
    PSPDFInstantErrorOldClient = 21,

    /**
     The operation could not be completed because the client and server have incompatible versions: the client is too new for the server.

     The server needs to be updated to a compatible version.
     You should update your server before releasing the updated client to ensure this error is never encountered on users’ devices.
     */
    PSPDFInstantErrorOldServer = 22,

    /**
     The JWT you specified has an invalid format.

     Instant performs limited offline validation of the strings that you pass into methods that require a JWT before
     even contacting the server. JWTs must…

     1. consist of a header, payload, and signature part,
     2. the payload needs to be a base64 URL encoded JSON object,
     3. which — at the very least — needs to contain a string for the key `document_id`.

     The string you provided either violates at least one of these rules, or contains invalid data for an optional
     claim — such as `layer_name` or `user_id`. For details, please inspect the `localizedDescription`.
     */
    PSPDFInstantErrorInvalidJWT = 32,

    /**
     The specified user ID is incompatible with the value stored on disk.

     To prevent data corruption, Instant verifies that you do not inadvertently “switch out” the user for a document
     descriptor. If the JWT you used to download a layer contained the `user_id` claim, that value is stored on disk.
     Whenever you attempt to reauthenticate the document descriptor, Instant then compares the stored value to the
     value encoded in the new JWT, and will fail with this error if the values do not match up.
     */
    PSPDFInstantErrorUserIDMismatch = 33,

    /**
     An attachment with the given ID does not exist in the disk cache.

     To find out whether or not the attachment actually exists, try downloading it from the server.
     */
    PSPDFInstantErrorAttachmentNotLoaded = 40,

    /**
     There is no attachment with the specified ID.

     A download request for the attachment with the given ID has been rejected by the server because it does not know of
     such an attachment.
     */
    PSPDFInstantErrorNoSuchAttachment = 41,

    /**
     An error occurred trying to create the attachment for an annotation.

     The affected annotation can be found under `PSPDFInstantErrorAnnotationKey`.
     */
    PSPDFInstantErrorCouldNotCreateAttachment = 42,

    /**
     The operation cannot be performed at this time, because the document descriptor is busy
     authenticating.

     You will encounter this error code when you are attempting to reauthenticate or sync a document
     descriptor that is already in the process of authenticating. The `userInfo` of error objects
     with this code will contain the document descriptor in question under the
     `PSPDFInstantErrorDocumentDescriptorKey`.
     */
    PSPDFInstantErrorAlreadyAuthenticating = 0x42,

    /**
     The operation cannot be performed at this time because the datastore for this document
     descriptor requires a content migration.

     You can encounter this error when you attempt to sync a `PSPDFInstantDocumentDescriptor` before
     asking it for a `PSPDFDocument`, after an update of the Instant framework that requires a deep
     content migration. (Instant performs simple migrations automatically.)
     The first such update was Instant 8.5.2 for iOS.

     The necessary content migration can be triggered in one of the following ways:

     1. implicitly: asking the document descriptor for a `PSPDFDocument` will start the migration
     2. explicitly: calling `-[<PSPDFInstantDocumentDescriptor> attemptContentMigration:]`
     will attempt to start a new migration — if it is not in progress already.

     The `userInfo` of error objects with this code will contain the document descriptor in question
     under the `PSPDFInstantErrorDocumentDescriptorKey`.
     */
    PSPDFInstantErrorContentMigrationNeeded = 0x60,

    /**
     The operation cannot be performed at this time because the datastore for this document
     descriptor is in the middle of a content migration.

     The most likely cause for this error is repeatedly calling `-[<PSPDFInstantDocumentDescriptor> attemptContentMigration:]`. You can, however, also run into this situation
     when attempting to explicitly sync a document descriptor that is currently performing a content
     migration.
     To recover from this error, you should generally just wait.

     The `userInfo` of error objects with this code will contain the document descriptor in question
     under the `PSPDFInstantErrorDocumentDescriptorKey`.
     */
    PSPDFInstantErrorPerformingContentMigration = 0x61,
} PSPDF_ENUM_AVAILABLE;

/// Key for `NSError` `userInfo` for the `PSPDFInstantDocumentDescriptorDescriptor` an error relates to, if applicable.
PSPDF_EXPORT NSString *const PSPDFInstantErrorDocumentDescriptorKey;

/// Key for `NSError` `userInfo` for the `PSPDFDocument` an error relates to, if applicable.
PSPDF_EXPORT NSString *const PSPDFInstantErrorDocumentKey;

/// Key for `NSError` `userInfo` for the annotation identifier an error relates to, if applicable.
PSPDF_EXPORT NSString *const PSPDFInstantErrorAnnotationIdentifierKey;

/**
 User info key for the (extended) SQLite error code as an `NSNumber` in the case of `PSPDFInstantErrorDatabaseAccessFailed`.

 A detailed discussions of these codes can be found at https://www.sqlite.org/rescode.html 

 @note **Important:** This value can very well be `nil`! (Not all database access errors need to be SQLite errors.)
 */
PSPDF_EXPORT NSString *const PSPDFInstantErrorSQLiteExtendedErrorCodeKey;

/**
 User info key for the detailed errors in the case of `PSPDFInstantErrorCouldNotPurgeDiskCacheEntries`.

 The value under this key is an `NSDictionary<NSString *, NSError *> *`, where each key represents a document ID that
 could not be purged, and the corresponding value captures the reason why this failed.
 */
PSPDF_EXPORT NSString *const PSPDFInstantErrorPurgeErrorsByDocumentIDKey;

/**
 User info key for the identifier of the attachment in the case of `PSPDFInstantErrorAttachmentNotLoaded` or
 `PSPDFInstantErrorNoSuchAttachment`.

 The value under this key is the identifier for the attachment that could not be accessed/fetched as an `NSString`.
 */
PSPDF_EXPORT NSString *const PSPDFInstantErrorAttachmentIDKey;

/**
 The annotation that caused an error.
 */
PSPDF_EXPORT NSString *const PSPDFInstantErrorAnnotationKey;

NS_ASSUME_NONNULL_END
