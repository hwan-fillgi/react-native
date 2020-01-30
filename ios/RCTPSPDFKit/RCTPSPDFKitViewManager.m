//
//  Copyright © 2018-2019 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "RCTPSPDFKitViewManager.h"
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTConvert+PSPDFDocument.h"
#import "RCTConvert+PSPDFAnnotationToolbarConfiguration.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUIManager.h>
#import "PSCCustomUserInterfaceView.h"

@import PSPDFKit;
@import PSPDFKitUI;
@interface RCTPSPDFKitViewManager ()

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *loadingLabel;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) UIViewController *viewController;

@end

@implementation RCTPSPDFKitViewManager

+(RCTPSPDFKitViewManager *) theSettingsData

{
    static RCTPSPDFKitViewManager *theSettingsData = nil;
    if (!theSettingsData) {
        theSettingsData = [[super allocWithZone:nil] init];
    }
    return theSettingsData;

}
+(id) allocWithZone:(NSZone *)zone

{

    return [self theSettingsData];

}

-(id) init
{
    self = [super init];
    if (self) {
        _rightPdf = FALSE;
    }
    return self;
}

RCT_EXPORT_MODULE()

RCT_CUSTOM_VIEW_PROPERTY(document, PSPDFDocument, RCTPSPDFKitView) {
  if (json) {
      self.viewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];

      //로딩화면설정
      self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(75, 155, 170, 170)];
      self.loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
      self.loadingView.clipsToBounds = YES;
      self.loadingView.layer.cornerRadius = 10.0;
        
      self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
      self.activityIndicator.frame = CGRectMake(65, 40, self.activityIndicator.bounds.size.width, self.activityIndicator.bounds.size.height);
      [self.loadingView addSubview:self.activityIndicator];
        
      self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 105, 130, 22)];
      self.loadingLabel.backgroundColor = [UIColor clearColor];
      self.loadingLabel.textColor = [UIColor whiteColor];
      self.loadingLabel.adjustsFontSizeToFitWidth = YES;
      self.loadingLabel.textAlignment = NSTextAlignmentCenter;
      self.loadingLabel.text = @"Loading...";
      [self.loadingView addSubview:self.loadingLabel];
        
      // ProgressBar Start
      [self.loadingView setCenter:self.viewController.view.center];
      [self.viewController.view addSubview:self.loadingView];
      self.loadingView.hidden = FALSE;
      self.activityIndicator.hidden = FALSE;
      [self.activityIndicator startAnimating];
      
      NSDictionary *dictionary = [RCTConvert NSDictionary:json];
      NSString *noteType = [dictionary objectForKey:@"noteType"];
      NSString *noteId = [dictionary objectForKey:@"noteId"];
      NSString *pdfURL = [NSString stringWithFormat:@"%@%@%@", @"https://fillgi-prod-image.s3-us-west-1.amazonaws.com/upload/", noteId, @".pdf"];
      view.noteId = noteId;
      view.noteType = noteType;
      _version = noteId;
      _noteType = noteType;
      
      if ([noteType isEqualToString:@"viewer"]) {
        NSLog(@"viewer");
        NSString *escapedPath = [pdfURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSLog(@"viewer escapedPath: %@", pdfURL);
        NSURL *url = [NSURL URLWithString:escapedPath];
          
        // Get the PDF Data from the url in a NSData Object
        NSData *pdfData = [[NSData alloc] initWithContentsOfURL:url];
        if (pdfData) {
            NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *filePath = [resourceDocPath stringByAppendingPathComponent:@"viewer.pdf"];
            [pdfData writeToFile:filePath atomically:YES];

            NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
            view.pdfController.document = [[PSPDFDocument alloc] initWithURL:fileURL];
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, view.pdfController.view.frame.size.width / 2, 0.0, 0.0);
            view.pdfController.documentViewController.layout.additionalScrollViewFrameInsets = contentInsets;
            NSLog(@"document url %@", view.pdfController.document.fileURL.path);
            
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = TRUE;
            self.loadingView.hidden = TRUE;
        } else {
            NSURL *docURL = [NSBundle.mainBundle URLForResource:@"note" withExtension:@"pdf"];
            view.pdfController.document = [[PSPDFDocument alloc] initWithURL:docURL];
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, view.pdfController.view.frame.size.width / 2, 0.0, 0.0);
            view.pdfController.documentViewController.layout.additionalScrollViewFrameInsets = contentInsets;
            NSLog(@"document url %@", view.pdfController.document.fileURL.path);
            
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = TRUE;
            self.loadingView.hidden = TRUE;
        }
      } else {
        //view.pdfController.document = [RCTConvert PSPDFDocument:json];
        NSURL *docURL = [NSBundle.mainBundle URLForResource:@"note" withExtension:@"pdf"];

        PSPDFDocument *documents = [[PSPDFDocument alloc] initWithURL:docURL];
        PSPDFPageTemplate *externalDocumentPageTemplate = [[PSPDFPageTemplate alloc] initWithDocument:documents sourcePageIndex:0];
        NSString *filename = [NSString stringWithFormat:@"%@%@", noteId, @".pdf"];
        NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:filename];
          
        //파일이 존재하지 않을때, url파일이 있는지 검사
        NSLog(@"불러오기");
        NSString *escapedPath = [pdfURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSLog(@"escapedPath: %@", escapedPath);
        NSURL *url = [NSURL URLWithString:escapedPath];
        
        NSData *pdfData = [[NSData alloc] initWithContentsOfURL:url];
          
        if (pdfData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Get the PDF Data from the url in a NSData Object
                NSData *pdfData = [[NSData alloc] initWithContentsOfURL:url];
                
                [pdfData writeToFile:filePath atomically:YES];

                NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
                view.pdfController.document = [[PSPDFDocument alloc] initWithURL:fileURL];
                UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, view.pdfController.view.frame.size.width / 2, 0.0, 0.0);
                view.pdfController.documentViewController.layout.additionalScrollViewFrameInsets = contentInsets;
                NSLog(@"document url %@", view.pdfController.document.fileURL.path);
                
                [self.activityIndicator stopAnimating];
                self.activityIndicator.hidden = TRUE;
                self.loadingView.hidden = TRUE;
            });
        } else {
            NSLog(@"no data");
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"생성하기");
                PSPDFDocumentEditor *documentEditor = [[PSPDFDocumentEditor alloc] init];
                // Add the first page. At least one is needed to be able to save the document.
                [documentEditor addPagesInRange:NSMakeRange(0, 1) withConfiguration:[PSPDFNewPageConfiguration newPageConfigurationWithPageTemplate:externalDocumentPageTemplate builderBlock:^(PSPDFNewPageConfigurationBuilder *builder) {
                    builder.pageSize = CGSizeMake(595, 842); // A4 in points
                }]];
                // Save to a new PDF file.
                [documentEditor saveToPath:filePath withCompletionBlock:^(PSPDFDocument * document, NSError *error) {
                    if (error) {
                        NSLog(@"Error saving document. Error: %@", error);
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
                            view.pdfController.document = [[PSPDFDocument alloc] initWithURL:fileURL];
                            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, view.pdfController.view.frame.size.width / 2, 0.0, 0.0);
                            view.pdfController.documentViewController.layout.additionalScrollViewFrameInsets = contentInsets;
                            NSLog(@"document url %@", view.pdfController.document.fileURL.path);
                            
                            [self.activityIndicator stopAnimating];
                            self.activityIndicator.hidden = TRUE;
                            self.loadingView.hidden = TRUE;
                        });
                    }
                }];
            });
        }
      }
      
    view.pdfController.document.delegate = (id<PSPDFDocumentDelegate>)view;
      
    // The author name may be set before the document exists. We set it again here when the document exists.
    if (view.annotationAuthorName) {
      view.pdfController.document.defaultAnnotationUsername = view.annotationAuthorName;
    }
  }
}

RCT_REMAP_VIEW_PROPERTY(pageIndex, pdfController.pageIndex, NSUInteger)

RCT_CUSTOM_VIEW_PROPERTY(noteId, NSString, RCTPSPDFKitView) {
  if (json) {
      NSLog(@"noteId: %@", json);
      view.noteId = json;
  }
}

RCT_CUSTOM_VIEW_PROPERTY(noteType, NSString, RCTPSPDFKitView) {
  if (json) {
      NSLog(@"noteType: %@", json);
      view.noteType = json;
  }
}

RCT_CUSTOM_VIEW_PROPERTY(configuration, PSPDFConfiguration, RCTPSPDFKitView) {
  if (json) {
    [view.pdfController updateConfigurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
      [builder setupFromJSON:json];
    }];
  }
}

RCT_CUSTOM_VIEW_PROPERTY(annotationAuthorName, NSString, RCTPSPDFKitView) {
  if (json) {
    view.pdfController.document.defaultAnnotationUsername = json;
    view.annotationAuthorName = json;
  }
}

RCT_CUSTOM_VIEW_PROPERTY(menuItemGrouping, PSPDFAnnotationToolbarConfiguration, RCTPSPDFKitView) {
  if (json) {
    PSPDFAnnotationToolbarConfiguration *configuration = [RCTConvert PSPDFAnnotationToolbarConfiguration:json];
    view.pdfController.annotationToolbarController.annotationToolbar.configurations = @[configuration];
  }
}

RCT_CUSTOM_VIEW_PROPERTY(leftBarButtonItems, NSArray<UIBarButtonItem *>, RCTPSPDFKitView) {
  if (json) {
    NSArray *leftBarButtonItems = [RCTConvert NSArray:json];
    [view setLeftBarButtonItems:leftBarButtonItems forViewMode:nil animated:NO];
  }
}

RCT_CUSTOM_VIEW_PROPERTY(rightBarButtonItems, NSArray<UIBarButtonItem *>, RCTPSPDFKitView) {
  if (json) {
    NSArray *rightBarButtonItems = [RCTConvert NSArray:json];
    [view setRightBarButtonItems:rightBarButtonItems forViewMode:nil animated:NO];
  }
}

RCT_CUSTOM_VIEW_PROPERTY(toolbarTitle, NSString, RCTPSPDFKitView) {
  if (json) {
    view.pdfController.title = json;
  }
}

RCT_EXPORT_VIEW_PROPERTY(hideNavigationBar, BOOL)

RCT_EXPORT_VIEW_PROPERTY(disableDefaultActionForTappedAnnotations, BOOL)

RCT_EXPORT_VIEW_PROPERTY(disableAutomaticSaving, BOOL)

RCT_REMAP_VIEW_PROPERTY(color, tintColor, UIColor)

RCT_CUSTOM_VIEW_PROPERTY(showCloseButton, BOOL, RCTPSPDFKitView) {
  if (json && [RCTConvert BOOL:json]) {
    view.pdfController.navigationItem.leftBarButtonItems = @[view.closeButton];
  }
}

RCT_EXPORT_VIEW_PROPERTY(onCloseButtonPressed, RCTBubblingEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onDocumentSaved, RCTBubblingEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onDocumentSaveFailed, RCTBubblingEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onDocumentLoadFailed, RCTBubblingEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onAnnotationTapped, RCTBubblingEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onAnnotationsChanged, RCTBubblingEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onStateChanged, RCTBubblingEventBlock)

RCT_EXPORT_METHOD(enterAnnotationCreationMode:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    BOOL success = [component enterAnnotationCreationMode];
    if (success) {
      resolve(@(success));
    } else {
      reject(@"error", @"Failed to enter annotation creation mode.", nil);
    }
  });
}

RCT_EXPORT_METHOD(exitCurrentlyActiveMode:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    BOOL success = [component exitCurrentlyActiveMode];
    if (success) {
      resolve(@(success));
    } else {
      reject(@"error", @"Failed to exit currently active mode.", nil);
    }
  });
}

RCT_EXPORT_METHOD(saveCurrentDocument:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSError *error;
    BOOL success = [component saveCurrentDocumentWithError:&error];
    if (success) {
      resolve(@(success));
    } else {
      reject(@"error", @"Failed to save document.", error);
    }
  });
}

RCT_REMAP_METHOD(getAnnotations, getAnnotations:(nonnull NSNumber *)pageIndex type:(NSString *)type reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSError *error;
    NSDictionary *annotations = [component getAnnotations:(PSPDFPageIndex)pageIndex.integerValue type:[RCTConvert annotationTypeFromInstantJSONType:type] error:&error];
    if (annotations) {
      resolve(annotations);
    } else {
      reject(@"error", @"Failed to get annotations.", error);
    }
  });
}

RCT_EXPORT_METHOD(addAnnotation:(id)jsonAnnotation reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSError *error;
    BOOL success = [component addAnnotation:jsonAnnotation error:&error];
    if (success) {
      resolve(@(success));
    } else {
      reject(@"error", @"Failed to add annotation.", error);
    }
  });
}

RCT_EXPORT_METHOD(removeAnnotation:(id)jsonAnnotation reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    BOOL success = [component removeAnnotationWithUUID:jsonAnnotation[@"uuid"]];
    if (success) {
      resolve(@(success));
    } else {
      reject(@"error", @"Failed to remove annotation.", nil);
    }
  });
}

RCT_EXPORT_METHOD(getAllUnsavedAnnotations:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSError *error;
    NSDictionary *annotations = [component getAllUnsavedAnnotationsWithError:&error];
    if (annotations) {
      resolve(annotations);
    } else {
      reject(@"error", @"Failed to get annotations.", error);
    }
  });
}

RCT_EXPORT_METHOD(getAllAnnotations:(NSString *)type reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSError *error;
    NSDictionary *annotations = [component getAllAnnotations:[RCTConvert annotationTypeFromInstantJSONType:type] error:&error];
    if (annotations) {
      resolve(annotations);
    } else {
      reject(@"error", @"Failed to get all annotations.", error);
    }
  });
}

RCT_EXPORT_METHOD(addAnnotations:(id)jsonAnnotations reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSError *error;
    BOOL success = [component addAnnotations:jsonAnnotations error:&error];
    if (success) {
      resolve(@(success));
    } else {
      reject(@"error", @"Failed to add annotations.", error);
    }
  });
}

RCT_EXPORT_METHOD(getFormFieldValue:(NSString *)fullyQualifiedName reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSDictionary *formElementDictionary = [component getFormFieldValue:fullyQualifiedName];
    if (formElementDictionary) {
      resolve(formElementDictionary);
    } else {
      reject(@"error", @"Failed to get form field value.", nil);
    }
  });
}

RCT_EXPORT_METHOD(setFormFieldValue:(nullable NSString *)value fullyQualifiedName:(NSString *)fullyQualifiedName reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    BOOL success = [component setFormFieldValue:value fullyQualifiedName:fullyQualifiedName];
     if (success) {
       resolve(@(success));
     } else {
       reject(@"error", @"Failed to set form field value.", nil);
     }
  });
}

RCT_EXPORT_METHOD(setLeftBarButtonItems:(nullable NSArray *)items viewMode:(nullable NSString *)viewMode animated:(BOOL)animated reactTag:(nonnull NSNumber *)reactTag) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    [component setLeftBarButtonItems:items forViewMode:viewMode animated:animated];
  });
}

RCT_EXPORT_METHOD(setRightBarButtonItems:(nullable NSArray *)items viewMode:(nullable NSString *)viewMode animated:(BOOL)animated reactTag:(nonnull NSNumber *)reactTag) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    [component setRightBarButtonItems:items forViewMode:viewMode animated:animated];
  });
}

RCT_EXPORT_METHOD(getLeftBarButtonItemsForViewMode:(nullable NSString *)viewMode reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSArray *leftBarButtonItems = [component getLeftBarButtonItemsForViewMode:viewMode];
    if (leftBarButtonItems) {
      resolve(leftBarButtonItems);
    } else {
      reject(@"error", @"Failed to get the left bar button items.", nil);
    }
  });
}

RCT_EXPORT_METHOD(getRightBarButtonItemsForViewMode:(nullable NSString *)viewMode reactTag:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    RCTPSPDFKitView *component = (RCTPSPDFKitView *)[self.bridge.uiManager viewForReactTag:reactTag];
    NSArray *rightBarButtonItems = [component getRightBarButtonItemsForViewMode:viewMode];
    if (rightBarButtonItems) {
      resolve(rightBarButtonItems);
    } else {
      reject(@"error", @"Failed to get the right bar button items.", nil);
    }
  });
}

- (UIView *)view {
  return [[RCTPSPDFKitView alloc] init];
}

@end
