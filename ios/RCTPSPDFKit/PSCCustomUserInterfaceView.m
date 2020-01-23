#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTPSPDFKitViewManager.h"

@interface PSCCustomUserInterfaceView () <PSPDFTabbedViewControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, nullable) PSPDFDocument *document;
@property (nonatomic, strong) UINavigationController *selectDocumentsNavController;
@property (nonatomic, strong) NSMutableArray *saveFile;
@property (nonatomic, nullable) NSNumber *mynumber;
@property (nonatomic, nullable) NSArray* jsonArray;

@end

@implementation PSCCustomUserInterfaceView
- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    NSString *mVersion = [[RCTPSPDFKitViewManager theSettingsData] version]; // 값 읽기
    NSLog(@"mVersion %@", mVersion);
    _documents = [NSMutableArray new];
    
    _rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
      
    NSArray *types = @[@"public.image", @"com.apple.application", @"public.item", @"public.data", @"public.content", @"public.audiovisual-content", @"public.audiovisual-content", @"public.data", @"public.composite-content"];

    _filePickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeImport];
    _filePickerController.delegate = self;
    _selectDocumentsNavController = [[UINavigationController alloc] initWithRootViewController:self.filePickerController];
      
    NSURL *requestURL = [NSURL URLWithString:@"https://www.google.co.kr/"];
      
    _webController = [[PSPDFWebViewController alloc] initWithURL:requestURL];

    _tabController = [[PSPDFTabbedViewController alloc] init];
    _tabController.delegate = self;
      
    [self.tabController.pdfController updateConfigurationWithoutReloadingWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        builder.pageMode = PSPDFPageModeSingle;
        builder.scrollDirection = PSPDFScrollDirectionVertical;
        builder.pageTransition = PSPDFPageTransitionScrollContinuous;
        builder.userInterfaceViewMode = PSPDFUserInterfaceViewModeAlways;
        builder.spreadFitting = PSPDFConfigurationSpreadFittingFill;
        builder.pageLabelEnabled = NO;
        builder.documentLabelEnabled = NO;
    }];
      
    NSString *getURL = [NSString stringWithFormat:@"%@?noteId=%@",@"https://lzlpcpj049.execute-api.us-west-1.amazonaws.com/prod/users/left", mVersion];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
      [request setURL:[NSURL URLWithString:getURL]];
      [request setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data!=nil) {
                NSDictionary* json = [NSJSONSerialization
                                      JSONObjectWithData:data
                                      options:kNilOptions
                                      error:&error];
            NSLog(@"json %@", json);
            NSString *left_pdf = [[json objectForKey:@"classes"] objectForKey:@"left_pdf"];
            NSLog(@"left_pdf %@", left_pdf);
            if (left_pdf == nil || [left_pdf isEqual:[NSNull null]]) {
            } else {
                NSError *error = NULL;
                NSData* data = [left_pdf dataUsingEncoding:NSUTF8StringEncoding];
                self.jsonArray = [NSJSONSerialization
                                                  JSONObjectWithData:data
                                                  options:kNilOptions
                                                  error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.jsonArray) {
                        for (int i = 0; i < self.jsonArray.count; i++) {
                            NSLog(@"json array %@", [self.jsonArray objectAtIndex:i]);
                            if ([[self.jsonArray objectAtIndex:i] isEqualToString:@"note_guide_0114(add highlighter).pdf"]) {
                                NSFileManager *fileManager = [NSFileManager defaultManager];
                                
                                NSURL *docURL = [NSBundle.mainBundle URLForResource:@"note_guide_0114(add highlighter)" withExtension:@"pdf"];
                                NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

                                NSString *filePath = [resourceDocPath stringByAppendingPathComponent:@"note_guide_0114(add highlighter).pdf"];
                                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                                NSError *err = [[NSError alloc] init];
                                if ([fileManager fileExistsAtPath:filePath]){
                                    PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                                    [self.documents addObject:document];
                                } else{
                                    BOOL result = [[NSFileManager defaultManager] copyItemAtPath:docURL.path toPath:filePath error:&err];
                                    if (result) {
                                        PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                                        [self.documents addObject:document];
                                    }
                                }
                            } else {
                                NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[self.jsonArray objectAtIndex:i]];
                                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                                PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                                [self.documents addObject:document];
                            }
                        }
                        NSLog(@"self.documents %@",  self.documents);
                        self.tabController.documents = [self.documents copy];
                        //self.tabController.documents = [self.documents copy];
                        //[self.tabController addDocument:self.documents makeVisible:YES animated:NO];
                        [self saveDocuments:self.documents];
                    }
                });
            }

        } else {
            NSLog(@"error");
        }
        //[self loadDocuments:self.jsonArray];
    }] resume];
    
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
    
    double f1 = recognizer.view.center.x + translation.x;
    NSNumber* num1 = [NSNumber numberWithDouble:f1];
    NSDictionary *notiDic=nil;
    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTime", nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytimes" object:nil userInfo:notiDic];
}

// 파일선택
#pragma mark - iCloud files
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 파일경로 저장
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        NSString *filename = url.lastPathComponent;
        NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *filePath = [resourceDocPath stringByAppendingPathComponent:filename];
        //NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:filename];
        NSError *err = [[NSError alloc] init];
        // Now create Request for the file that was saved in your documents folder
        NSURL *url = [NSURL fileURLWithPath:filePath];
        
        if ([fileManager fileExistsAtPath:filePath]){
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSLog(@"file exist. %@", fileURL);
            PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
            if (self.tabController.documents.count == 0) {
                [self.documents addObject:document];
                self.tabController.documents = [self.documents copy];
                [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
            } else {
                Boolean sameFlag = NO;
                for (int i = 0; i < self.tabController.documents.count; i++) {
                    if ([document.UID isEqualToString:self.tabController.documents[i].UID]) {
                        sameFlag = YES;
                    }
                }
                if (sameFlag == NO) {
                    //self.tabController.documents = [self.documents copy];
                    [self.tabController addDocument:document makeVisible:YES animated:NO];
                    [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
                }
            }
        } else{
            BOOL result = [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:filePath error:&err];
            if (result) {
                NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
                PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                if (self.tabController.documents.count == 0) {
                    [self.documents addObject:document];
                    self.tabController.documents = [self.documents copy];
                    [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
                } else {
                    Boolean sameFlag = NO;
                    for (int i = 0; i < self.tabController.documents.count; i++) {
                        if ([document.UID isEqualToString:self.tabController.documents[i].UID]) {
                            sameFlag = YES;
                        }
                    }
                    if (sameFlag == NO) {
                        //self.tabController.documents = [self.documents copy];
                        [self.tabController addDocument:document makeVisible:YES animated:NO];
                        [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
                    }
                }
            }
            else {
                NSLog(@"Import failed. %@", err.localizedDescription);
            }
        }
        [self saveDocuments:self.documents];
    }
}

-(void)saveDocuments:(NSMutableArray *)noti{
    self.saveFile = [NSMutableArray new];
    NSLog(@"document save %@", self.tabController.documents);
    for (int i = 0; i < self.tabController.documents.count; i++) {
        NSLog(@"document save %@", self.tabController.documents[i].fileName);
        [self.saveFile addObject:self.tabController.documents[i].fileName];
    }
    NSDictionary *notiDic=nil;
    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:self.saveFile,@"play", nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlay" object:nil userInfo:notiDic];
}

- (void)tabbedPDFController:(PSPDFTabbedViewController *)tabbedPDFController didCloseDocument:(PSPDFDocument *)document{
    NSLog(@"document CLOSE");
    [self saveDocuments:self.documents];
}

- (void)updateScrubberBarFrameAnimated:(BOOL)animated {
    [super updateScrubberBarFrameAnimated:animated];
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

-(void)setPlayTim:(NSNotification *)noti{
    NSDictionary *notiDic=[noti userInfo];
    self.mynumber = [notiDic objectForKey:@"playTim"];
    self.selectDocumentsNavController.navigationBarHidden = YES;
    self.selectDocumentsNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.selectDocumentsNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:self.selectDocumentsNavController animated:YES completion:nil];
}

-(void)setPlayTi:(NSNotification *)noti{
    NSDictionary *notiDic=[noti userInfo];
    self.mynumber = [notiDic objectForKey:@"playTi"];
    int i = [self.mynumber intValue];
    
    if (i == 1) {
        @try {
           [self.navigationController pushViewController:self.webController animated:NO];
        } @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
             [self.navigationController popToViewController:self.webController animated:NO];
        } @finally {
            //NSLog(@"finally");
        }
    } else if (i == 2) {
        @try {
           [self.navigationController pushViewController:self.tabController animated:NO];
        } @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
             [self.navigationController popToViewController:self.tabController animated:NO];
        } @finally {
            //NSLog(@"finally");
        }
    }
}

- (NSString *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];

    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;

    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];

    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return nil;
    }

    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}


@end
