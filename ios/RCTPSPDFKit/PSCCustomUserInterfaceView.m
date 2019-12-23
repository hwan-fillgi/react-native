#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"

@interface PSCCustomUserInterfaceView ()

@property (nonatomic, nullable) PSPDFDocument *document;
@property (nonatomic, strong) NSMutableArray *documents;
@property (nonatomic, strong) UINavigationController *selectDocumentsNavController;
@property (nonatomic, strong) NSString *currentItem;
@property (nonatomic, nullable) NSNumber *mynumber;

@end

@implementation PSCCustomUserInterfaceView
- (instancetype)initWithFrame:(CGRect)frame {
    
  if ((self = [super initWithFrame:frame])) {
    
    _documents = [NSMutableArray new];
    
    _rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
      
    NSArray *types = @[@"public.image", @"com.apple.application", @"public.item", @"public.data", @"public.content", @"public.audiovisual-content", @"public.movie", @"public.audiovisual-content", @"public.video", @"public.audio", @"public.text", @"public.data", @"public.zip-archive", @"com.pkware.zip-archive", @"public.composite-content", @"public.text"];

    _filePickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    _filePickerController.delegate = self;
    _selectDocumentsNavController = [[UINavigationController alloc] initWithRootViewController:self.filePickerController];
      
    NSURL *requestURL = [NSURL URLWithString:@"https://www.naver.com/"];
    NSURL *baseURL = [NSBundle.mainBundle URLForResource:@"youtube2" withExtension:@"html"];
    NSURL *docURL = [NSBundle.mainBundle URLForResource:@"Sample" withExtension:@"pdf"];

    NSString *html = requestURL.parameterString;

    _webController = [[PSPDFWebViewController alloc] initWithURL:baseURL];

    _tabController = [[PSPDFTabbedViewController alloc] init];
    self.document = [[PSPDFDocument alloc] initWithURL:docURL];

    [self.documents addObject:self.document];
    self.tabController.documents = [self.documents copy];
      
    [self.tabController.pdfController updateConfigurationWithoutReloadingWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        builder.pageMode = PSPDFPageModeSingle;
        builder.scrollDirection = PSPDFScrollDirectionVertical;
        builder.pageTransition = PSPDFPageTransitionScrollContinuous;
        builder.userInterfaceViewMode = PSPDFUserInterfaceViewModeAlways;
        builder.spreadFitting = PSPDFConfigurationSpreadFittingFill;
        builder.pageLabelEnabled = NO;
        builder.documentLabelEnabled = NO;
    }];

    _navigationController = [[UINavigationController alloc] initWithRootViewController:self.tabController];
    _navigationController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationController.navigationBarHidden = true;

    //_navigationController.navigationBar.hidden = true;
    [self addSubview:self.navigationController.view];

    UIImageView *imageView = [[UIImageView alloc]init];
    [imageView setImage:[PSPDFKitGlobal imageNamed:@"scroll_bar"]];
    [imageView sizeToFit];
    imageView.userInteractionEnabled = YES;
    imageView.center = CGPointMake(self.navigationController.view.frame.size.width / 2, self.navigationController.view.frame.size.height / 2);
    [self addSubview:imageView];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [imageView addGestureRecognizer:pan];

    [NSLayoutConstraint activateConstraints:
        @[[self.navigationController.view.topAnchor constraintEqualToAnchor:self.topAnchor constant:74],
        [self.navigationController.view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.navigationController.view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.navigationController.view.trailingAnchor constraintEqualToAnchor:imageView.centerXAnchor]
        ]];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setPlayTim:) name:@"setPlaytims" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setPlayTi:) name:@"setPlaytis" object:nil];
  }
  return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {

    CGPoint translation = [recognizer translationInView:self];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + 0);

    [NSLayoutConstraint activateConstraints:
        @[[self.navigationController.view.trailingAnchor constraintEqualToAnchor:recognizer.view.centerXAnchor]
        ]];
    [recognizer setTranslation:CGPointZero inView:self];
    NSLog(@"asd: %f", translation.x);
    
    double f1 = recognizer.view.center.x + translation.x;
    NSNumber* num1 = [NSNumber numberWithDouble:f1];
    NSDictionary *notiDic=nil;
    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTime", nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytimes" object:nil userInfo:notiDic];
}

#pragma mark - iCloud files
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    NSLog(@"original URL: %@", url);
    NSURL *docURL = [NSBundle.mainBundle URLForResource:@"note" withExtension:@"pdf"];
    PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:url];
    [self.documents addObject:document];
    self.tabController.documents = [self.documents copy];
}

- (void)updateScrubberBarFrameAnimated:(BOOL)animated {
    [super updateScrubberBarFrameAnimated:animated];

    // Stick scrubber bar to the top.
//    CGRect newFrame = self.dataSource.contentRect;
//    newFrame.size.height = 44.f;
//    self.scrubberBar.frame = newFrame;
}

- (void)updateThumbnailBarFrameAnimated:(BOOL)animated {
    [super updateThumbnailBarFrameAnimated:animated];
}

- (void)updatePageLabelFrameAnimated:(BOOL)animated {
    [super updatePageLabelFrameAnimated:animated];
}

+ (PSPDFDocument *)PSPDFDocument:(NSString *)string {
  NSURL *url;

  if ([string hasPrefix:@"/"]) {
    url = [NSURL fileURLWithPath:string];
  } else {
    url = [NSBundle.mainBundle URLForResource:string withExtension:nil];
  }

  NSString *fileExtension = url.pathExtension.lowercaseString;
  BOOL isImageFile = [fileExtension isEqualToString:@"png"] || [fileExtension isEqualToString:@"jpeg"] || [fileExtension isEqualToString:@"jpg"];
  if (isImageFile) {
    return [[PSPDFImageDocument alloc] initWithImageURL:url];
  } else {
    return [[PSPDFDocument alloc] initWithURL:url];
  }
}

//- (void)presentTabs:(CDVInvokedUrlCommand *)command {
//    NSArray *paths = [command argumentAtIndex:0];
//
//    PSPDFTabbedViewController *tabbedViewController = [[PSPDFTabbedViewController alloc] init];
////    NSMutableArray *documents = [NSMutableArray new];
//    for (NSString *path in paths) {
//        PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:[self fileURLWithPath:path]];
//        if (document) {
//            [documents addObject:document];
//        }
//    }
//    tabbedViewController.documents = [documents copy];
//    _navigationController = [[UINavigationController alloc] initWithRootViewController:tabbedViewController];
//
//    if (!_navigationController.presentingViewController) {
//        [self.viewController presentViewController:_navigationController animated:YES completion:^{
//
//            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
//                                        callbackId:command.callbackId];
//        }];
//    } else {
//        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR]
//                                    callbackId:command.callbackId];
//    }
//}
-(void)setPlayTim:(NSNotification *)noti{
    NSDictionary *notiDic=[noti userInfo];
    self.mynumber = [notiDic objectForKey:@"playTim"];
    double i = [self.mynumber doubleValue];
    NSLog(@"asd: %f",i);
    self.selectDocumentsNavController.navigationBarHidden = YES;
    self.selectDocumentsNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.selectDocumentsNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self.rootViewController presentViewController:self.selectDocumentsNavController animated:YES completion:nil];
}

-(void)setPlayTi:(NSNotification *)noti{
    NSDictionary *notiDic=[noti userInfo];
    self.mynumber = [notiDic objectForKey:@"playTi"];
    int i = [self.mynumber intValue];
    
    NSLog(@"browser: %d",i);
    if (i == 1) {
        NSURL *requestURL = [NSURL URLWithString:@"https://www.naver.com/"];

        _webController = [[PSPDFWebViewController alloc] initWithURL:requestURL];
        [self.navigationController initWithRootViewController:self.webController];
    } else if (i == 2) {
        _tabController = [[PSPDFTabbedViewController alloc] init];
        [self.tabController.pdfController updateConfigurationWithoutReloadingWithBuilder:^(PSPDFConfigurationBuilder *builder) {
            builder.pageMode = PSPDFPageModeSingle;
            builder.scrollDirection = PSPDFScrollDirectionVertical;
            builder.pageTransition = PSPDFPageTransitionScrollContinuous;
            builder.userInterfaceViewMode = PSPDFUserInterfaceViewModeAlways;
            builder.spreadFitting = PSPDFConfigurationSpreadFittingFill;
            builder.pageLabelEnabled = NO;
            builder.documentLabelEnabled = NO;
        }];
        self.tabController.documents = [self.documents copy];
        [self.navigationController initWithRootViewController:self.tabController];
    }
}
@end
