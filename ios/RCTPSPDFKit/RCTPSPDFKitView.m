//
//  Copyright © 2018-2019 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <PSPDFKitUI/PSPDFDocumentViewController.h>
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "PSCCustomUserInterfaceView.h"
#import <AWSCore/AWSCore.h>
#import <AWSS3/AWSS3TransferUtility.h>
#import <AWSCognito/AWSCognito.h>
#import <PDFKit/PDFKit.h>

#define VALIDATE_DOCUMENT(document, ...) { if (!document.isValid) { NSLog(@"Document is invalid."); if (self.onDocumentLoadFailed) { self.onDocumentLoadFailed(@{@"error": @"Document is invalid."}); } return __VA_ARGS__; }}

@interface RCTPSPDFKitView ()<PSPDFDocumentDelegate, PSPDFViewControllerDelegate, PSPDFFlexibleToolbarContainerDelegate>

@property (nonatomic, nullable) NSString *result;
@property (nonatomic, nullable) UIViewController *controller;
@property (nonatomic, nullable) NSNumber *mynumber;
@property (nonatomic, nullable) UIViewController *topController;
@property (nonatomic, nullable) UINavigationBar *navBarProxy;
@property (nonatomic, nullable) UIToolbar *toolbarProxy;
@property (nonatomic, nullable) UIColor *mainColor;
@property (nonatomic, nullable) UIColor *secondaryColor;
@property (nonatomic, nullable) UIPanGestureRecognizer *recognizer;
@property (nonatomic, nullable) BOOL *browser;
@property (nonatomic) PSPDFDocumentViewLayout *layout;
@property (nonatomic, nullable) PSPDFDocumentEditor *editor;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *loadingLabel;
@property (nonatomic, retain) UIView *loadingView;

@end

@implementation RCTPSPDFKitView
- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
       initWithRegionType:AWSRegionUSWest2
       identityPoolId:@"us-west-2:ff7db21f-d7ea-4a9a-9ebe-5737bbc3e127"];

    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];

    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
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
    self.loadingLabel.text = @"Saving...";
    [self.loadingView addSubview:self.loadingLabel];
                                    
    _browser = YES;
    _mainColor = [UIColor blackColor];
    _secondaryColor = [UIColor whiteColor];
    _result = [[NSString alloc] init];

    // Navigation bar and toolbar customization. We're limiting appearance customization to instances that are
    // inside `PSPDFNavigationController` so that we don't affect the appearance of certain system controllers.
    _navBarProxy = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[PSPDFNavigationController.class]];
    _toolbarProxy = [UIToolbar appearanceWhenContainedInInstancesOfClasses:@[PSPDFNavigationController.class]];
    NSURL *requestURL = [NSURL URLWithString:@"https://fillgi-prod-image.s3-us-west-1.amazonaws.com/upload/1577950286309Awe133616.pdf"];

    _webController = [[PSPDFWebViewController alloc] initWithURL:requestURL];
    
    _pdfController = [[PSPDFViewController alloc] initWithDocument:self.pdfController.document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        [builder overrideClass:PSPDFUserInterfaceView.class withClass:PSCCustomUserInterfaceView.class];
    }]];
    
    _pdfController.delegate = self;
    _pdfController.annotationToolbarController.delegate = self;
    
    NSLog(@"note id %@", self.pdfController.document);
    _closeButton = [[UIBarButtonItem alloc] initWithImage:[PSPDFKitGlobal imageNamed:@"icon_getout"] style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonPressed:)];
    _addButton = [[UIBarButtonItem alloc] initWithImage:[PSPDFKitGlobal imageNamed:@"icon_add"] style:UIBarButtonItemStylePlain target:self action:@selector(addDocuments:)];
    _browserButton = [[UIBarButtonItem alloc] initWithImage:[PSPDFKitGlobal imageNamed:@"icon_tab-change"] style:UIBarButtonItemStylePlain target:self action:@selector(switchBrowser:)];
    _pageButton = [[UIBarButtonItem alloc] initWithImage:[PSPDFKitGlobal imageNamed:@"icon_add-note"] style:UIBarButtonItemStylePlain target:self action:@selector(addPages:)];
      
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(annotationChangedNotification:) name:PSPDFAnnotationChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(annotationChangedNotification:) name:PSPDFAnnotationsAddedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(annotationChangedNotification:) name:PSPDFAnnotationsRemovedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setPlayTime:) name:@"setPlaytimes" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setPlay:) name:@"setPlay" object:nil];
  }
  
  return self;
}

- (void)removeFromSuperview {
  // When the React Native `PSPDFKitView` in unmounted, we need to dismiss the `PSPDFViewController` to avoid orphan popovers.
  // See https://github.com/PSPDFKit/react-native/issues/277
  [self.pdfController dismissViewControllerAnimated:NO completion:NULL];
  [super removeFromSuperview];
}

- (void)dealloc {
  [self destroyViewControllerRelationship];
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didMoveToWindow {
    NSLog(@"note id %@", self.noteId);
    // On iOS 13 and later.
    if (@available(iOS 13, *)) {
        // `UINavigationBar` styling.
        UINavigationBarAppearance *navigationBarAppearance = [[UINavigationBarAppearance alloc] init];
        navigationBarAppearance.backgroundColor = self.mainColor;

        self.navBarProxy.standardAppearance = navigationBarAppearance;
        self.navBarProxy.compactAppearance = navigationBarAppearance;
        self.navBarProxy.scrollEdgeAppearance = navigationBarAppearance;

        // `UIToolbar` styling.
        UIToolbarAppearance *toolbarAppearance = [[UIToolbarAppearance alloc] init];
        toolbarAppearance.backgroundColor = self.mainColor;

        // Apply the same appearance styling to all sizes of `UIToolbar`.
        self.toolbarProxy.standardAppearance = toolbarAppearance;
        self.toolbarProxy.compactAppearance = toolbarAppearance;

        // Make sure we're getting a light title and status bar.
        self.navBarProxy.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    } else {
        // On iOS 12 and earlier.
        self.navBarProxy.barTintColor = self.mainColor;
        self.toolbarProxy.barTintColor = self.mainColor;

        // Make sure we're getting a light title and status bar.
        self.navBarProxy.barStyle = UIBarStyleBlack;
    }

  self.navBarProxy.tintColor = self.secondaryColor;
  self.toolbarProxy.tintColor = self.secondaryColor;

  self.controller = self.pspdf_parentViewController;
  if (self.controller == nil || self.window == nil || self.topController != nil) {
    return;
  }
    
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, self.pdfController.view.frame.size.width / 2, 0.0, 0.0);
  self.pdfController.documentViewController.layout.additionalScrollViewFrameInsets = contentInsets;
  self.topController = self.pdfController;
  self.topController = [[PSPDFNavigationController alloc] initWithRootViewController:self.pdfController];

  UIView *topControllerView = self.topController.view;
  topControllerView.translatesAutoresizingMaskIntoConstraints = NO;

  [self addSubview:topControllerView];
  [self.controller addChildViewController:self.topController];
  [self.topController didMoveToParentViewController:self.controller];

  [NSLayoutConstraint activateConstraints:
   @[[topControllerView.topAnchor constraintEqualToAnchor:self.topAnchor],
     [topControllerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
     [topControllerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
     [topControllerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
   ]];

}

- (void)destroyViewControllerRelationship {
  if (self.topController.parentViewController) {
    [self.topController willMoveToParentViewController:nil];
    [self.topController removeFromParentViewController];
  }
}

- (void)closeNote {
  if (self.onCloseButtonPressed) {
    self.onCloseButtonPressed(@{});
  } else {
    // try to be smart and pop if we are not displayed modally.
    BOOL shouldDismiss = YES;
    if (self.pdfController.navigationController) {
      UIViewController *topViewController = self.pdfController.navigationController.topViewController;
      UIViewController *parentViewController = self.pdfController.parentViewController;
      if ((topViewController == self.pdfController || topViewController == parentViewController) && self.pdfController.navigationController.viewControllers.count > 1) {
        [self.pdfController.navigationController popViewControllerAnimated:YES];
        shouldDismiss = NO;
      }
    }
    if (shouldDismiss) {
      [self.pdfController dismissViewControllerAnimated:YES completion:NULL];
    }
  }
}

- (void)closeButtonPressed:(nullable id)sender {
    if ([self.noteType isEqualToString:@"viewer"]) {
        [self closeNote];
    } else{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Fillgi Says" message:@"Do you want to save the note?" preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
        {
            NSLog(@"제발 되라 %@", self.documents);
            NSString *jsonString = NULL;
            if (!(self.documents == nil || [self.documents isEqual:[NSNull null]])) {
                NSLog(@"제발 되라3 %@", self.documents);
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.documents options:NSJSONWritingPrettyPrinted error:nil];
                jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            
            NSLog(@"json %@", jsonString);
            
            // ProgressBar Start
            [self.loadingView setCenter:self.center];
            [self addSubview:self.loadingView];
            self.activityIndicator.hidden= FALSE;
            [self.activityIndicator startAnimating];

            PSPDFDocument *document = self.pdfController.document;
            if (!document) return;
            PSPDFDocumentEditor *editor = [[PSPDFDocumentEditor alloc] initWithDocument:document];
            if (!editor) return;

            NSURL *fileURL = self.pdfController.document.fileURL;
            NSString *uploadURL = [NSString stringWithFormat:@"%@%@%@", @"https://fillgi-prod-image.s3-us-west-1.amazonaws.com/upload/", self.noteId, @".pdf"];
            NSString *keyValue = [NSString stringWithFormat:@"%@%@%@", @"upload/", self.noteId, @".pdf"];
            NSString *imageValue = [NSString stringWithFormat:@"%@%@%@", @"right_image/", self.noteId, @".png"];
            NSString *imgValue = [NSString stringWithFormat:@"%@%@", self.noteId, @".png"];

            // Create path.
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imgValue];
            NSURL *rightImage = [[NSURL alloc] initFileURLWithPath:filePath];

            AWSS3TransferUtilityUploadExpression *expression = [AWSS3TransferUtilityUploadExpression new];
            expression.progressBlock = ^(AWSS3TransferUtilityTask *task, NSProgress *progress) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Do something e.g. Update a progress bar.
                    NSLog(@"progressz");
                });
            };

            AWSS3TransferUtilityUploadCompletionHandlerBlock completionHandler = ^(AWSS3TransferUtilityUploadTask *task, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"File upload completed");
                        // 기본 구성에 URLSession 생성
                        NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
                        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
                        // request URL 설정
                        NSURL *url = url = [NSURL URLWithString:@"https://lzlpcpj049.execute-api.us-west-1.amazonaws.com/prod/users/note"];
                        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];

                        // UTF8 인코딩을 사용하여 POST 문자열 매개 변수를 데이터로 변환
                        NSString *postParams = [NSString stringWithFormat:@"right_pdf=%@&note_id=%@&left_pdf=%@", uploadURL, self.noteId, jsonString];
                        NSData *postData = [postParams dataUsingEncoding:NSUTF8StringEncoding];

                        // 셋
                        [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                        [urlRequest setHTTPMethod:@"POST"];
                        [urlRequest setHTTPBody:postData];

                        // dataTask 생성
                        NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                            if (data!=nil)
                            {
                                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                NSLog(@"result %@", [json objectForKey:@"result"]);
                                self.result = [json objectForKey:@"result"];
                                if([[json objectForKey:@"result"] isEqualToString:@"success"]){
                                    NSLog(@"success");
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.activityIndicator stopAnimating];
                                        self.activityIndicator.hidden= TRUE;
                                        [self closeNote];
                                    });
                                }
                            } else {
                                NSLog(@"error");
                            }
                        }];
                        [dataTask resume];
                    });
             };

            AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];

            // Save and overwrite the document.
            [editor saveWithCompletionBlock:^(PSPDFDocument *savedDocument, NSError *error) {
                if (error) {
                    NSLog(@"Document editing failed: %@", error);
                    return;
                }
                // Access the UI on the main thread.
                dispatch_async(dispatch_get_main_queue(), ^{
                    PDFView * pdfView = [[PDFView alloc] initWithFrame : CGRectMake(0, 0, 424, 600)];
                    pdfView.document = [[PDFDocument alloc] initWithURL : [NSURL fileURLWithPath : savedDocument.fileURL.path]];

                    UIImage *thumbnailImage = [[pdfView.document pageAtIndex:0] thumbnailOfSize:CGSizeMake(424, 600) forBox:kPDFDisplayBoxMediaBox];
                    // Save image.
                    if ([UIImagePNGRepresentation(thumbnailImage) writeToFile:filePath atomically:YES]) {
                        NSLog(@"Success");
                        [[transferUtility uploadFile:fileURL bucket:@"fillgi-prod-image" key:keyValue contentType:@"application/pdf" expression:nil completionHandler:completionHandler]continueWithBlock:^id(AWSTask *task){
                            if (task.error) {
                                NSLog(@"Error: %@", task.error);
                            }
                            if (task.result) {
                                // Do something with uploadTask.
                            }
                            return nil;
                        }];

                        [[transferUtility uploadFile:rightImage bucket:@"fillgi-prod-image" key:imageValue contentType:@"image/png" expression:nil completionHandler:completionHandler]continueWithBlock:^id(AWSTask *task){
                            if (task.error) {
                                NSLog(@"Error: %@", task.error);
                            }
                            if (task.result) {
                                // Do something with uploadTask.
                            }
                            return nil;
                        }];
                    }
                    else{
                        NSLog(@"Error");
                    }
                });
            }];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
            [self closeNote];
        }];
        [alertController addAction:ok];
        [alertController addAction:cancel];

        [self.pdfController presentViewController:alertController animated:YES completion:nil];
    }
}

-(void)setPlay:(NSNotification *)noti{
    _documents = [NSMutableArray new];
    NSDictionary *notiDic=[noti userInfo];
    [self.documents addObjectsFromArray:[notiDic objectForKey:@"play"]];
}

- (void)addPages:(nullable id)sender {
    PSPDFDocument *document = self.pdfController.document;
    if (!document) return;
    PSPDFDocumentEditor *editor = [[PSPDFDocumentEditor alloc] initWithDocument:document];
    if (!editor) return;
    
    NSURL *docURL = [NSBundle.mainBundle URLForResource:@"note" withExtension:@"pdf"];
    PSPDFDocument *documents = [[PSPDFDocument alloc] initWithURL:docURL];
    PSPDFPageTemplate *externalDocumentPageTemplate = [[PSPDFPageTemplate alloc] initWithDocument:documents sourcePageIndex:0];
    // Add a new page as the first page.
    PSPDFNewPageConfiguration *newPageConfiguration = [PSPDFNewPageConfiguration newPageConfigurationWithPageTemplate:externalDocumentPageTemplate builderBlock:^(PSPDFNewPageConfigurationBuilder *builder) {
        builder.pageSize = CGSizeMake(595, 842); // A4 in points
    }];
    [editor addPagesInRange:NSMakeRange(document.pageCount, 1) withConfiguration:newPageConfiguration];

    // Save and overwrite the document.
    [editor saveWithCompletionBlock:^(PSPDFDocument *savedDocument, NSError *error) {
        if (error) {
            NSLog(@"Document editing failed: %@", error);
            return;
        }
        // Access the UI on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.pdfController reloadData];
        });
    }];
}

- (void)addDocuments:(nullable id)sender {
    NSLog(@"addDocuments");
    double f1 = 0.11;
    NSNumber* num1 = [NSNumber numberWithDouble:f1];
    NSDictionary *notiDic=nil;
    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTim", nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytims" object:nil userInfo:notiDic];
}

- (void)switchBrowser:(nullable id)sender {
    NSLog(@"bValue1 : %@", (self.browser ? @"YES" : @"NO"));
    
    if (self.browser) {
        int f1 = 1;
        NSNumber* num1 = [NSNumber numberWithDouble:f1];
        NSDictionary *notiDic=nil;
        notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTi", nil];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytis" object:nil userInfo:notiDic];

        self.browser = !self.browser;
    } else {
        int f1 = 2;
        NSNumber* num1 = [NSNumber numberWithDouble:f1];
        NSDictionary *notiDic=nil;
        notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTi", nil];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytis" object:nil userInfo:notiDic];

        self.browser = !self.browser;
    }
}

- (UIViewController *)pspdf_parentViewController {
  UIResponder *parentResponder = self;
  while ((parentResponder = parentResponder.nextResponder)) {
    if ([parentResponder isKindOfClass:UIViewController.class]) {
      return (UIViewController *)parentResponder;
    }
  }
  return nil;
}

- (BOOL)enterAnnotationCreationMode {
  [self.pdfController setViewMode:PSPDFViewModeDocument animated:YES];
  [self.pdfController.annotationToolbarController updateHostView:nil container:nil viewController:self.pdfController];
  return [self.pdfController.annotationToolbarController showToolbarAnimated:YES completion:NULL];
}

- (BOOL)exitCurrentlyActiveMode {
  return [self.pdfController.annotationToolbarController hideToolbarAnimated:YES completion:NULL];
}

- (BOOL)saveCurrentDocumentWithError:(NSError *_Nullable *)error {
  return [self.pdfController.document saveWithOptions:nil error:error];
}

#pragma mark - PSPDFDocumentDelegate

- (void)pdfDocumentDidSave:(nonnull PSPDFDocument *)document {
  if (self.onDocumentSaved) {
    self.onDocumentSaved(@{});
  }
}

- (void)pdfDocument:(PSPDFDocument *)document saveDidFailWithError:(NSError *)error {
  if (self.onDocumentSaveFailed) {
    self.onDocumentSaveFailed(@{@"error": error.description});
  }
}

#pragma mark - PSPDFViewControllerDelegate

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController didTapOnAnnotation:(PSPDFAnnotation *)annotation annotationPoint:(CGPoint)annotationPoint annotationView:(UIView<PSPDFAnnotationPresenting> *)annotationView pageView:(PSPDFPageView *)pageView viewPoint:(CGPoint)viewPoint {
  if (self.onAnnotationTapped) {
    NSData *annotationData = [annotation generateInstantJSONWithError:NULL];
    NSDictionary *annotationDictionary = [NSJSONSerialization JSONObjectWithData:annotationData options:kNilOptions error:NULL];
    self.onAnnotationTapped(annotationDictionary);
  }
  return self.disableDefaultActionForTappedAnnotations;
}

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldSaveDocument:(nonnull PSPDFDocument *)document withOptions:(NSDictionary<PSPDFDocumentSaveOption,id> *__autoreleasing  _Nonnull * _Nonnull)options {
  return !self.disableAutomaticSaving;
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didConfigurePageView:(PSPDFPageView *)pageView forPageAtIndex:(NSInteger)pageIndex {
  [self onStateChangedForPDFViewController:pdfController pageView:pageView pageAtIndex:pageIndex];
}

- (void)pdfViewController:(PSPDFViewController *)pdfController willBeginDisplayingPageView:(PSPDFPageView *)pageView forPageAtIndex:(NSInteger)pageIndex {
  [self onStateChangedForPDFViewController:pdfController pageView:pageView pageAtIndex:pageIndex];
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didChangeDocument:(nullable PSPDFDocument *)document {
  VALIDATE_DOCUMENT(document)
}

#pragma mark - PSPDFFlexibleToolbarContainerDelegate

- (void)flexibleToolbarContainerDidShow:(PSPDFFlexibleToolbarContainer *)container {
  PSPDFPageIndex pageIndex = self.pdfController.pageIndex;
  PSPDFPageView *pageView = [self.pdfController pageViewForPageAtIndex:pageIndex];
  [self onStateChangedForPDFViewController:self.pdfController pageView:pageView pageAtIndex:pageIndex];
}

- (void)flexibleToolbarContainerDidHide:(PSPDFFlexibleToolbarContainer *)container {
  PSPDFPageIndex pageIndex = self.pdfController.pageIndex;
  PSPDFPageView *pageView = [self.pdfController pageViewForPageAtIndex:pageIndex];
  [self onStateChangedForPDFViewController:self.pdfController pageView:pageView pageAtIndex:pageIndex];
}

#pragma mark - Instant JSON

- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)getAnnotations:(PSPDFPageIndex)pageIndex type:(PSPDFAnnotationType)type error:(NSError *_Nullable *)error {
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, nil);
  
  NSArray <PSPDFAnnotation *> *annotations = [document annotationsForPageAtIndex:pageIndex type:type];
  NSArray <NSDictionary *> *annotationsJSON = [RCTConvert instantJSONFromAnnotations:annotations error:error];
  return @{@"annotations" : annotationsJSON};
}

- (BOOL)addAnnotation:(id)jsonAnnotation error:(NSError *_Nullable *)error {
  NSData *data;
  if ([jsonAnnotation isKindOfClass:NSString.class]) {
    data = [jsonAnnotation dataUsingEncoding:NSUTF8StringEncoding];
  } else if ([jsonAnnotation isKindOfClass:NSDictionary.class])  {
    data = [NSJSONSerialization dataWithJSONObject:jsonAnnotation options:0 error:error];
  } else {
    NSLog(@"Invalid JSON Annotation.");
    return NO;
  }
  
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, NO)
  PSPDFDocumentProvider *documentProvider = document.documentProviders.firstObject;
  
  BOOL success = NO;
  if (data) {
    PSPDFAnnotation *annotation = [PSPDFAnnotation annotationFromInstantJSON:data documentProvider:documentProvider error:error];
    if (annotation) {
      success = [document addAnnotations:@[annotation] options:nil];
    }
  }
  
  if (!success) {
    NSLog(@"Failed to add annotation.");
  }
  
  return success;
}

- (BOOL)removeAnnotationWithUUID:(NSString *)annotationUUID {
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, NO)
  BOOL success = NO;
  
  NSArray<PSPDFAnnotation *> *allAnnotations = [[document allAnnotationsOfType:PSPDFAnnotationTypeAll].allValues valueForKeyPath:@"@unionOfArrays.self"];
  for (PSPDFAnnotation *annotation in allAnnotations) {
    // Remove the annotation if the uuids match.
    if ([annotation.uuid isEqualToString:annotationUUID]) {
      success = [document removeAnnotations:@[annotation] options:nil];
      break;
    }
  }
  
  if (!success) {
    NSLog(@"Failed to remove annotation.");
  }
  return success;
}

- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)getAllUnsavedAnnotationsWithError:(NSError *_Nullable *)error {
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, nil)
  
  PSPDFDocumentProvider *documentProvider = document.documentProviders.firstObject;
  NSData *data = [document generateInstantJSONFromDocumentProvider:documentProvider error:error];
  NSDictionary *annotationsJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:error];
  return annotationsJSON;
}

- (NSDictionary<NSString *, NSArray<NSDictionary *> *> *)getAllAnnotations:(PSPDFAnnotationType)type error:(NSError *_Nullable *)error {
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, nil)

  NSArray<PSPDFAnnotation *> *annotations = [[document allAnnotationsOfType:type].allValues valueForKeyPath:@"@unionOfArrays.self"];
  NSArray <NSDictionary *> *annotationsJSON = [RCTConvert instantJSONFromAnnotations:annotations error:error];
  return @{@"annotations" : annotationsJSON};
}

- (BOOL)addAnnotations:(id)jsonAnnotations error:(NSError *_Nullable *)error {
  NSData *data;
  if ([jsonAnnotations isKindOfClass:NSString.class]) {
    data = [jsonAnnotations dataUsingEncoding:NSUTF8StringEncoding];
  } else if ([jsonAnnotations isKindOfClass:NSDictionary.class])  {
    data = [NSJSONSerialization dataWithJSONObject:jsonAnnotations options:0 error:error];
  } else {
    NSLog(@"Invalid JSON Annotations.");
    return NO;
  }
  
  PSPDFDataContainerProvider *dataContainerProvider = [[PSPDFDataContainerProvider alloc] initWithData:data];
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, NO)
  PSPDFDocumentProvider *documentProvider = document.documentProviders.firstObject;
  BOOL success = [document applyInstantJSONFromDataProvider:dataContainerProvider toDocumentProvider:documentProvider lenient:NO error:error];
  if (!success) {
    NSLog(@"Failed to add annotations.");
  }
  
  [self.pdfController reloadPageAtIndex:self.pdfController.pageIndex animated:NO];
  return success;
}

#pragma mark - Forms

- (NSDictionary<NSString *, id> *)getFormFieldValue:(NSString *)fullyQualifiedName {
  if (fullyQualifiedName.length == 0) {
    NSLog(@"Invalid fully qualified name.");
    return nil;
  }
  
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, nil)
  
  for (PSPDFFormElement *formElement in document.formParser.forms) {
    if ([formElement.fullyQualifiedFieldName isEqualToString:fullyQualifiedName]) {
      id formFieldValue = formElement.value;
      return @{@"value": formFieldValue ?: [NSNull new]};
    }
  }
  
  return @{@"error": @"Failed to get the form field value."};
}

- (BOOL)setFormFieldValue:(NSString *)value fullyQualifiedName:(NSString *)fullyQualifiedName {
  if (fullyQualifiedName.length == 0) {
    NSLog(@"Invalid fully qualified name.");
    return NO;
  }
  
  PSPDFDocument *document = self.pdfController.document;
  VALIDATE_DOCUMENT(document, NO)

  BOOL success = NO;
  for (PSPDFFormElement *formElement in document.formParser.forms) {
    if ([formElement.fullyQualifiedFieldName isEqualToString:fullyQualifiedName]) {
      if ([formElement isKindOfClass:PSPDFButtonFormElement.class]) {
        if ([value isEqualToString:@"selected"]) {
          [(PSPDFButtonFormElement *)formElement select];
          success = YES;
        } else if ([value isEqualToString:@"deselected"]) {
          [(PSPDFButtonFormElement *)formElement deselect];
          success = YES;
        }
      } else if ([formElement isKindOfClass:PSPDFChoiceFormElement.class]) {
        ((PSPDFChoiceFormElement *)formElement).selectedIndices = [NSIndexSet indexSetWithIndex:value.integerValue];
        success = YES;
      } else if ([formElement isKindOfClass:PSPDFTextFieldFormElement.class]) {
        formElement.contents = value;
        success = YES;
      } else if ([formElement isKindOfClass:PSPDFSignatureFormElement.class]) {
        NSLog(@"Signature form elements are not supported.");
        success = NO;
      } else {
        NSLog(@"Unsupported form element.");
        success = NO;
      }
      break;
    }
  }
  return success;
}

#pragma mark - Notifications

- (void)annotationChangedNotification:(NSNotification *)notification {
  id object = notification.object;
  NSArray <PSPDFAnnotation *> *annotations;
  if ([object isKindOfClass:NSArray.class]) {
    annotations = object;
  } else if ([object isKindOfClass:PSPDFAnnotation.class]) {
    annotations = @[object];
  } else {
    if (self.onAnnotationsChanged) {
      self.onAnnotationsChanged(@{@"error" : @"Invalid annotation error."});
    }
    return;
  }
  
  NSString *name = notification.name;
  NSString *change;
  if ([name isEqualToString:PSPDFAnnotationChangedNotification]) {
    change = @"changed";
  } else if ([name isEqualToString:PSPDFAnnotationsAddedNotification]) {
    change = @"added";
  } else if ([name isEqualToString:PSPDFAnnotationsRemovedNotification]) {
    change = @"removed";
  }
  
  NSArray <NSDictionary *> *annotationsJSON = [RCTConvert instantJSONFromAnnotations:annotations error:NULL];
  if (self.onAnnotationsChanged) {
    self.onAnnotationsChanged(@{@"change" : change, @"annotations" : annotationsJSON});
  }
}

#pragma mark - Customize the Toolbar

- (void)setLeftBarButtonItems:(nullable NSArray <NSString *> *)items forViewMode:(nullable NSString *) viewMode animated:(BOOL)animated {
  NSMutableArray *leftItems = [NSMutableArray array];
  for (NSString *barButtonItemString in items) {
      UIBarButtonItem *barButtonItem;
      if([barButtonItemString isEqualToString:@"closeButtonItem"]) {
          barButtonItem = _closeButton;
      } else if([barButtonItemString isEqualToString:@"addButtonItem"]) {
          barButtonItem = _addButton;
      } else if([barButtonItemString isEqualToString:@"browserButtonItem"]) {
          barButtonItem = _browserButton;
      } else{
          barButtonItem = [RCTConvert uiBarButtonItemFrom:barButtonItemString forViewController:self.pdfController];
      }
    if (barButtonItem && ![self.pdfController.navigationItem.rightBarButtonItems containsObject:barButtonItem]) {
      [leftItems addObject:barButtonItem];
    }
  }
  
  if (viewMode.length) {
    [self.pdfController.navigationItem setLeftBarButtonItems:[leftItems copy] forViewMode:[RCTConvert PSPDFViewMode:viewMode] animated:animated];
  } else {
    [self.pdfController.navigationItem setLeftBarButtonItems:[leftItems copy] animated:animated];
  }
}

- (void)setRightBarButtonItems:(nullable NSArray <NSString *> *)items forViewMode:(nullable NSString *) viewMode animated:(BOOL)animated {
  NSMutableArray *rightItems = [NSMutableArray array];
  for (NSString *barButtonItemString in items) {
    UIBarButtonItem *barButtonItem = [RCTConvert uiBarButtonItemFrom:barButtonItemString forViewController:self.pdfController];
    if([barButtonItemString isEqualToString:@"pageButtonItem"]) {
        barButtonItem = _pageButton;
    } else{
        barButtonItem = [RCTConvert uiBarButtonItemFrom:barButtonItemString forViewController:self.pdfController];
    }
    if (barButtonItem && ![self.pdfController.navigationItem.leftBarButtonItems containsObject:barButtonItem]) {
      [rightItems addObject:barButtonItem];
    }
  }
  
  if (viewMode.length) {
    [self.pdfController.navigationItem setRightBarButtonItems:[rightItems copy] forViewMode:[RCTConvert PSPDFViewMode:viewMode] animated:animated];
  } else {
    [self.pdfController.navigationItem setRightBarButtonItems:[rightItems copy] animated:animated];
  }
}

- (NSArray <NSString *> *)getLeftBarButtonItemsForViewMode:(NSString *)viewMode {
  NSArray *items;
  if (viewMode.length) {
    items = [self.pdfController.navigationItem leftBarButtonItemsForViewMode:[RCTConvert PSPDFViewMode:viewMode]];
  } else {
    items = [self.pdfController.navigationItem leftBarButtonItems];
  }
  
  return [self buttonItemsStringFromUIBarButtonItems:items];
}

- (NSArray <NSString *> *)getRightBarButtonItemsForViewMode:(NSString *)viewMode {
  NSArray *items;
  if (viewMode.length) {
    items = [self.pdfController.navigationItem rightBarButtonItemsForViewMode:[RCTConvert PSPDFViewMode:viewMode]];
  } else {
    items = [self.pdfController.navigationItem rightBarButtonItems];
  }
  
  return [self buttonItemsStringFromUIBarButtonItems:items];
}

#pragma mark - Helpers

- (void)onStateChangedForPDFViewController:(PSPDFViewController *)pdfController pageView:(PSPDFPageView *)pageView pageAtIndex:(NSInteger)pageIndex {
  if (self.onStateChanged) {
    BOOL isDocumentLoaded = [pdfController.document isValid];
    PSPDFPageCount pageCount = pdfController.document.pageCount;
    BOOL isAnnotationToolBarVisible = [pdfController.annotationToolbarController isToolbarVisible];
    BOOL hasSelectedAnnotations = pageView.selectedAnnotations.count > 0;
    BOOL hasSelectedText = pageView.selectionView.selectedText.length > 0;
    BOOL isFormEditingActive = NO;
    for (PSPDFAnnotation *annotation in pageView.selectedAnnotations) {
      if ([annotation isKindOfClass:PSPDFWidgetAnnotation.class]) {
        isFormEditingActive = YES;
        break;
      }
    }
    
    self.onStateChanged(@{@"documentLoaded" : @(isDocumentLoaded),
                          @"currentPageIndex" : @(pageIndex),
                          @"pageCount" : @(pageCount),
                          @"annotationCreationActive" : @(isAnnotationToolBarVisible),
                          @"annotationEditingActive" : @(hasSelectedAnnotations),
                          @"textSelectionActive" : @(hasSelectedText),
                          @"formEditingActive" : @(isFormEditingActive)
    });
  }
}

- (NSArray <NSString *> *)buttonItemsStringFromUIBarButtonItems:(NSArray <UIBarButtonItem *> *)barButtonItems {
  NSMutableArray *barButtonItemsString = [NSMutableArray new];
  [barButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull barButtonItem, NSUInteger idx, BOOL * _Nonnull stop) {
    NSString *buttonNameString = [RCTConvert stringBarButtonItemFrom:barButtonItem forViewController:self.pdfController];
    if (buttonNameString) {
      [barButtonItemsString addObject:buttonNameString];
    }
  }];
  return [barButtonItemsString copy];
}

// 델리게이터 함수 구현 값을 받음
-(void)setPlayTime:(NSNotification *)noti{
    NSDictionary *notiDic=[noti userInfo];
    self.mynumber = [notiDic objectForKey:@"playTime"];
    double i = [self.mynumber doubleValue];
    NSLog(@"asd: %f",i);
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, i, 0.0, 0.0);
    self.pdfController.documentViewController.layout.additionalScrollViewFrameInsets = contentInsets;
}

@end
