//
//  Copyright © 2018-2019 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>
#import "PSCCustomUserInterfaceView.h"
#import "Instant.h"

@import PSPDFKit;
@import PSPDFKitUI;

NS_ASSUME_NONNULL_BEGIN

@interface RCTPSPDFKitView: UIView

//@property (nonatomic, retain) PSPDFViewController *pdfController;
@property (nonatomic, retain) PSPDFInstantViewController *pdfController;
@property (nonatomic) BOOL hideNavigationBar;
@property (nonatomic, retain) UIBarButtonItem *closeButton;
@property (nonatomic, retain) UIBarButtonItem *addButton;
@property (nonatomic, retain) UIBarButtonItem *browserButton;
@property (nonatomic, retain) UIBarButtonItem *pageButton;
@property (nonatomic, retain) UIBarButtonItem *collaboButton;
@property (nonatomic) BOOL disableDefaultActionForTappedAnnotations;
@property (nonatomic) BOOL disableAutomaticSaving;
@property (nonatomic, copy, nullable) NSString *annotationAuthorName;
@property (nonatomic, copy) RCTBubblingEventBlock onCloseButtonPressed;
@property (nonatomic, copy) RCTBubblingEventBlock onDocumentSaved;
@property (nonatomic, copy) RCTBubblingEventBlock onDocumentSaveFailed;
@property (nonatomic, copy) RCTBubblingEventBlock onDocumentLoadFailed;
@property (nonatomic, copy) RCTBubblingEventBlock onAnnotationTapped;
@property (nonatomic, copy) RCTBubblingEventBlock onAnnotationsChanged;
@property (nonatomic, copy) RCTBubblingEventBlock onStateChanged;
@property (nonatomic, retain) UIDocumentPickerViewController *filePickerController;
@property (nonatomic, retain) UIViewController *rootViewController;
@property (readonly, nonatomic) PSPDFNewPageType pageType;
@property (nonatomic, retain) NSString *noteId;
@property (nonatomic, retain) NSString *noteType;
@property (nonatomic, retain) PSPDFWebViewController *webController;
@property (nonatomic, nullable) NSMutableArray *documents;
@property (nonatomic, nullable) PSCCustomUserInterfaceView *customView;

/// Annotation Toolbar
- (BOOL)enterAnnotationCreationMode;
- (BOOL)exitCurrentlyActiveMode;

/// Document
- (BOOL)saveCurrentDocumentWithError:(NSError *_Nullable *)error;

/// Anotations
- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)getAnnotations:(PSPDFPageIndex)pageIndex type:(PSPDFAnnotationType)type error:(NSError *_Nullable *)error;
- (BOOL)addAnnotation:(id)jsonAnnotation error:(NSError *_Nullable *)error;
- (BOOL)removeAnnotationWithUUID:(NSString *)annotationUUID;
- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)getAllUnsavedAnnotationsWithError:(NSError *_Nullable *)error;
- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)getAllAnnotations:(PSPDFAnnotationType)type error:(NSError *_Nullable *)error;
- (BOOL)addAnnotations:(NSString *)jsonAnnotations error:(NSError *_Nullable *)error;

/// Forms
- (NSDictionary<NSString *, NSString *> *)getFormFieldValue:(NSString *)fullyQualifiedName;
- (BOOL)setFormFieldValue:(NSString *)value fullyQualifiedName:(NSString *)fullyQualifiedName;

// Toolbar buttons customizations
- (void)setLeftBarButtonItems:(nullable NSArray <NSString *> *)items forViewMode:(nullable NSString *) viewMode animated:(BOOL)animated;
- (void)setRightBarButtonItems:(nullable NSArray <NSString *> *)items forViewMode:(nullable NSString *) viewMode animated:(BOOL)animated;
- (NSArray <NSString *> *)getLeftBarButtonItemsForViewMode:(NSString *)viewMode;
- (NSArray <NSString *> *)getRightBarButtonItemsForViewMode:(NSString *)viewMode;

@end

NS_ASSUME_NONNULL_END
