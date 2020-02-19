//
//  Copyright © 2017-2020 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <PSPDFKitUI/PSPDFViewController.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A specialized variant of `PSPDFViewController` that supports annotation synchronization.
 
 Showing a document managed by Instant in any other view controller is not supported.

 @note Instant only supports a subset of PSPDFKit’s annotation types. As such, this class sanitizes
 any `PSPDFConfiguration` passed to its designated initializer, `updateConfigurationWithBuilder:`,
 or `updateConfigurationWithoutReloadingWithBuilder:`.<br>
 If you choose to set the builder’s `editableAnnotationTypes` to `nil`, all supported annotation
 types will be editable. If you set `editableAnnotationTypes` to an empty set, no annotations will
 be editable.
 */
PSPDF_CLASS_AVAILABLE @interface PSPDFInstantViewController : PSPDFViewController

/**
 Whether the view controller should listen for server changes when visible.

 When `YES`, the view controller will take care of subscribing to and unsubscribing from live changes from the server
 when it is moved on or off screen. Note that setting this value to `NO` does not mean that you will not receive any
 changes from the server:<br>
 Whenever a `PSPDFInstantDocumentDescriptor` is being synced, all of the related documents are updated automatically. So
 if, for example, you display a secondary `PSPDFInstantViewController` on an external display, while you are editing in
 a primary `PSPDFInstantViewController`, that secondary view controller will be updated even if it has
 `shouldListenForServerChangesWhenVisible` set to `NO`.
 
 The default value of this property is `YES`.
 */
@property (nonatomic) IBInspectable BOOL shouldListenForServerChangesWhenVisible;

/**
 Triggers a one-shot sync action.

 When the document isn’t Instant enabled, or already syncing, this method does nothing. Otherwise, it triggers a one-
 time sync action. This is useful when you don’t want automatic syncing to reduce the energy footprint of your app.
 */
- (IBAction)syncChanges:(nullable id)sender;

/**
 Whether the view controller should automatically handle certain critical errors.

 If `YES`, when this view controller’s view is visible and a `PSPDFInstantErrorIncompatibleVersion` error occurs for the
 current document, automatic syncing will be disabled and an alert will be shown that tells the user the app must be
 updated.

 Defaults to `YES`.

 We recommended that you make your app approriately handle all errors that Instant might encounter, and then set this to
 `NO`.
 */
@property (nonatomic) BOOL shouldShowCriticalErrors;

@end

NS_ASSUME_NONNULL_END
