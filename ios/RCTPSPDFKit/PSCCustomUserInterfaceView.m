#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTPSPDFKitViewManager.h"
#import <AWSS3/AWSS3TransferUtility.h>

@import Instant;
@interface PSCCustomUserInterfaceView () <PSPDFTabbedViewControllerDelegate, UIDocumentPickerDelegate, PSPDFInstantClientDelegate>

@property (nonatomic, nullable) PSPDFDocument *document;
@property (nonatomic, strong) UINavigationController *selectDocumentsNavController;
@property (nonatomic, strong) NSMutableArray *saveFile;
@property (nonatomic, nullable) NSNumber *mynumber;
@property (nonatomic, nullable) NSArray* jsonArray;
@property (nonatomic, nullable) NSString* JWT;
@property (nonatomic, nullable) PSPDFInstantViewController *instantViewController;
@property (nonatomic, nullable) PSPDFInstantClient *instantClient;
@property (nonatomic, nullable) SocketIOClient *socket;
@property (nonatomic) Boolean sendFlag;
@property (nonatomic) Boolean closeFlag;

@end

@implementation PSCCustomUserInterfaceView
- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.noteId = [[RCTPSPDFKitViewManager theSettingsData] version]; // 값 읽기
    self.socket = [[RCTPSPDFKitViewManager theSettingsData] socket];
    NSLog(@"mVersion %@", self.socket);
    
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
       initWithRegionType:AWSRegionUSWest2
       identityPoolId:@"us-west-2:ff7db21f-d7ea-4a9a-9ebe-5737bbc3e127"];

    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];

    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
      
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
      
    [self loadPDF];
      
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

    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;

    [NSLayoutConstraint activateConstraints:
        @[[self.navigationController.view.topAnchor constraintEqualToAnchor:self.topAnchor constant:self.navigationController.navigationBar.frame.size.height + statusBarSize.height],
        [self.navigationController.view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.navigationController.view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.navigationController.view.trailingAnchor constraintEqualToAnchor:imageView.centerXAnchor]
        ]];
      
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setPlayTim:) name:@"setPlaytims" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setPlayTi:) name:@"setPlaytis" object:nil];
      
    NSNumber* num1 = [NSNumber numberWithDouble:self.navigationController.view.frame.size.width / 2];
    NSDictionary *notiDic=nil;
    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTime", nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytimes" object:nil userInfo:notiDic];
  }
    
  [self.socket on:@"recMsg" callback:^(NSArray* data, SocketAckEmitter* ack) {
      NSLog(@"self.sendFlag : %@", (self.sendFlag ? @"YES" : @"NO"));
      if (self.sendFlag == NO) {
          self.documents = [NSMutableArray new];
          NSLog(@"self.sendFlag : %@", (self.closeFlag ? @"YES" : @"NO"));
          NSDictionary *avatar = [data objectAtIndex:0];
          NSLog(@"GET JSON %@", avatar);
          NSArray *avatarimage = [avatar objectForKey:@"pdf"];
          NSLog(@"GET JSON %@", avatarimage);
          if (avatarimage) {
              NSFileManager *fileManager = [NSFileManager defaultManager];
              for (int i = 0; i < avatarimage.count; i++) {
                  NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                  NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[avatarimage objectAtIndex:i]];
                  if ([fileManager fileExistsAtPath:filePath]){
                      NSLog(@"file exist");
                  } else{
                      NSLog(@"file not exist");
                      NSString *pdfURL = [NSString stringWithFormat:@"%@%@%@%@", @"https://fillgi-prod-image.s3-us-west-1.amazonaws.com/", self.noteId, @"/", [avatarimage objectAtIndex:i]];
                      NSString *escapedPath = [pdfURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                      NSLog(@"viewer escapedPath: %@", pdfURL);
                      NSURL *url = [NSURL URLWithString:escapedPath];
                        
                      // Get the PDF Data from the url in a NSData Object
                      NSData *pdfData = [[NSData alloc] initWithContentsOfURL:url];
                      if (pdfData) {
                          NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                          NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[avatarimage objectAtIndex:i]];
                          [pdfData writeToFile:filePath atomically:YES];
                      }
                  }
                  NSLog(@"viewer filePath: %@", filePath);
                  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                  PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                  [self.documents addObject:document];
              }

              NSLog(@"self.documents %@",  self.documents);
              self.tabController.documents = [self.documents copy];
          }
      } else {
          self.sendFlag = NO;
      }
  }];
    
  [self.socket on:@"recClose" callback:^(NSArray* data, SocketAckEmitter* ack) {
      if (self.closeFlag == NO) {
          self.documents = [NSMutableArray new];
          NSLog(@"self.sendFlag : %@", (self.closeFlag ? @"YES" : @"NO"));
          NSDictionary *avatar = [data objectAtIndex:0];
          NSArray *avatarimage = [avatar objectForKey:@"pdf"];
          NSLog(@"GET JSON %@", avatarimage);
          if (avatarimage) {
              for (int i = 0; i < avatarimage.count; i++) {
                  NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                  NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[avatarimage objectAtIndex:i]];
                  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                  PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                  [self.documents addObject:document];
              }

              NSLog(@"self.documents %@",  self.documents);
              self.tabController.documents = [self.documents copy];
          }
      } else {
          self.closeFlag = NO;
      }
  }];
    
    [self.socket on:@"recPicker" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"recPicker %@", data);
    }];
  return self;
}

- (void)updateScrubberBarFrameAnimated:(BOOL)animated {
    [super updateScrubberBarFrameAnimated:animated];

    // Stick scrubber bar to the top.
    CGRect newFrame = self.dataSource.contentRect;
    newFrame.size.height = 44.f;
    self.scrubberBar.frame = newFrame;
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

- (void)loadPDF {
    NSLog(@"laod pdf");
    // 왼쪽 pdf 불러오는 부분
    self.noteId = [self.noteId stringByReplacingOccurrencesOfString:@"%20" withString:@" "];

    NSString *getURL = [NSString stringWithFormat:@"%@?noteId=%@",@"https://1g3h2oj5z6.execute-api.us-west-1.amazonaws.com/prod/users/left", self.noteId];
    NSLog(@"getURL %@", getURL);
    // Create NSURLSession object
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *escapedPath = [getURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"escapedPath: %@", escapedPath);
    // Create a NSURL object.
    NSURL *url = [NSURL URLWithString:escapedPath];

    // Create NSURLSessionDataTask task object by url and session object.
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data!=nil) {
            NSLog(@"GET data %@", data);
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

            NSLog(@"GET JSON %@", json);
            NSString *left_pdf = [[json objectForKey:@"classes"] objectForKey:@"left_pdf"];
            NSLog(@"left_pdf %@", left_pdf);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (left_pdf == nil || [left_pdf isEqual:[NSNull null]]) {
                    
                } else {
                    NSError *error = NULL;
                    NSData* data = [left_pdf dataUsingEncoding:NSUTF8StringEncoding];
                    self.jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    
                    if (self.jsonArray) {
                        for (int i = 0; i < self.jsonArray.count; i++) {
                            NSFileManager *fileManager = [NSFileManager defaultManager];
                            NSLog(@"json array %@", [self.jsonArray objectAtIndex:i]);
                            if ([[self.jsonArray objectAtIndex:i] isEqualToString:@"note_guide_0114(add highlighter).pdf"]) {
                                NSURL *docURL = [NSBundle.mainBundle URLForResource:@"note_guide_0114(add highlighter)" withExtension:@"pdf"];
                                NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

                                NSString *filePath = [resourceDocPath stringByAppendingPathComponent:@"note_guide_0114(add highlighter).pdf"];
                                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                                NSError *err = [[NSError alloc] init];
                                if ([fileManager fileExistsAtPath:filePath]){
                                    NSLog(@"file exist");
                                    PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                                    [self.documents addObject:document];
                                } else{
                                    NSLog(@"file not exist");
                                    BOOL result = [[NSFileManager defaultManager] copyItemAtPath:docURL.path toPath:filePath error:&err];
                                    if (result) {
                                        PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                                        [self.documents addObject:document];
                                    }
                                }
                            } else {
                                NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[self.jsonArray objectAtIndex:i]];
                                if ([fileManager fileExistsAtPath:filePath]){
                                    NSLog(@"file exist");
                                } else{
                                    NSLog(@"file not exist");
                                    NSString *pdfURL = [NSString stringWithFormat:@"%@%@%@%@", @"https://fillgi-prod-image.s3-us-west-1.amazonaws.com/", self.noteId, @"/", [self.jsonArray objectAtIndex:i]];
                                    NSString *escapedPath = [pdfURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                    NSLog(@"viewer escapedPath: %@", pdfURL);
                                    NSURL *url = [NSURL URLWithString:escapedPath];
                                      
                                    // Get the PDF Data from the url in a NSData Object
                                    NSData *pdfData = [[NSData alloc] initWithContentsOfURL:url];
                                    if (pdfData) {
                                        NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                        NSString *filePath = [resourceDocPath stringByAppendingPathComponent:[self.jsonArray objectAtIndex:i]];
                                        [pdfData writeToFile:filePath atomically:YES];
                                    }
                                }
                                NSURL *fileURL = [NSURL fileURLWithPath:filePath];
                                PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
                                [self.documents addObject:document];
                            }
                        }
                        NSLog(@"self.documents %@",  self.documents);
                        self.tabController.documents = [self.documents copy];
                        [self saveDocuments:self.documents];
                    }
                }
            });
        }
    }];

    // Begin task.
    [task resume];
}

// 파일선택 하는 부분
#pragma mark - iCloud files
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self.socket emit:@"picker" with:@[@{@"comment": @"noteId"}]];
//    //self.sendFlag = NO;
//    NSURL *fileURL = url;
//    NSString *filename = url.lastPathComponent;
//    NSString *keyValue = [NSString stringWithFormat:@"%@%@%@", self.noteId, @"/", filename];
//
//    AWSS3TransferUtilityUploadExpression *expression = [AWSS3TransferUtilityUploadExpression new];
//    expression.progressBlock = ^(AWSS3TransferUtilityTask *task, NSProgress *progress) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Do something e.g. Update a progress bar.
//            NSLog(@"progressz");
//        });
//    };
//
//    AWSS3TransferUtilityUploadCompletionHandlerBlock completionHandler = ^(AWSS3TransferUtilityUploadTask *task, NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSLog(@"File upload completed");
//                self.saveFile = [NSMutableArray new];
//                NSLog(@"document save %@", self.tabController.documents);
//                for (int i = 0; i < self.tabController.documents.count; i++) {
//                    NSLog(@"document save %@", self.tabController.documents[i].fileName);
//                    [self.saveFile addObject:self.tabController.documents[i].fileName];
//                }
//                NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
//                self.saveFile, @"pdf",
//                nil];
//
//                NSMutableArray * arr = [[NSMutableArray alloc] init];
//
//                [arr addObject:jsonDictionary];
//                [self.socket emit:@"pdf" with:arr];
//            });
//     };
//
//    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
//
//    [[transferUtility uploadFile:fileURL bucket:@"fillgi-prod-image" key:keyValue contentType:@"application/pdf" expression:nil completionHandler:completionHandler]continueWithBlock:^id(AWSTask *task){
//        if (task.error) {
//            NSLog(@"Error: %@", task.error);
//        }
//        if (task.result) {
//            // Do something with uploadTask.
//            self.sendFlag = YES;
//        }
//        return nil;
//    }];
//
//    NSLog(@"documentPicker url %@", url);
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    // 파일경로 저장
//    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
//        NSString *resourceDocPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//        NSString *filePath = [resourceDocPath stringByAppendingPathComponent:filename];
//        //NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:filename];
//        NSError *err = [[NSError alloc] init];
//        // Now create Request for the file that was saved in your documents folder
//        if ([fileManager fileExistsAtPath:filePath]){
//            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
//            NSLog(@"file exist. %@", fileURL);
//            PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
//            if (self.tabController.documents.count == 0) {
//                [self.tabController addDocument:document makeVisible:YES animated:NO];
//                [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
//            } else {
//                Boolean sameFlag = NO;
//                for (int i = 0; i < self.tabController.documents.count; i++) {
//                    if ([document.UID isEqualToString:self.tabController.documents[i].UID]) {
//                        sameFlag = YES;
//                    }
//                }
//                if (sameFlag == NO) {
//                    //self.tabController.documents = [self.documents copy];
//                    [self.tabController addDocument:document makeVisible:YES animated:NO];
//                    [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
//                }
//            }
//        } else{
//            BOOL result = [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:filePath error:&err];
//            if (result) {
//                NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
//                PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:fileURL];
//                if (self.tabController.documents.count == 0) {
//                    [self.tabController addDocument:document makeVisible:YES animated:NO];
//                    [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
//                } else {
//                    Boolean sameFlag = NO;
//                    for (int i = 0; i < self.tabController.documents.count; i++) {
//                        if ([document.UID isEqualToString:self.tabController.documents[i].UID]) {
//                            sameFlag = YES;
//                        }
//                    }
//                    if (sameFlag == NO) {
//                        //self.tabController.documents = [self.documents copy];
//                        [self.tabController addDocument:document makeVisible:YES animated:NO];
//                        [self.tabController setVisibleDocument:document scrollToPosition:NO animated:NO];
//                    }
//                }
//            }
//            else {
//                NSLog(@"Import failed. %@", err.localizedDescription);
//            }
//        }
//        [self saveDocuments:self.documents];
//    }
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
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.saveFile options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    // 기본 구성에 URLSession 생성
    NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
    // request URL 설정
    NSURL *url = url = [NSURL URLWithString:@"https://1g3h2oj5z6.execute-api.us-west-1.amazonaws.com/prod/users/leftpdf"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];

    // UTF8 인코딩을 사용하여 POST 문자열 매개 변수를 데이터로 변환
    NSString *postParams = [NSString stringWithFormat:@"note_id=%@&left_pdf=%@", self.noteId, jsonString];
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
            if([[json objectForKey:@"result"] isEqualToString:@"success"]){
                NSLog(@"success");
            }
        } else {
            NSLog(@"error");
        }
    }];
    [dataTask resume];
}

- (void)tabbedPDFController:(PSPDFTabbedViewController *)tabbedPDFController didCloseDocument:(PSPDFDocument *)document{
    NSLog(@"document CLOSE %@", document);
    self.saveFile = [NSMutableArray new];
    NSLog(@"document save %@", self.tabController.documents);
    for (int i = 0; i < self.tabController.documents.count; i++) {
        NSLog(@"document save %@", self.tabController.documents[i].fileName);
        [self.saveFile addObject:self.tabController.documents[i].fileName];
    }
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
    self.saveFile, @"pdf",
    nil];
    
    NSMutableArray * arr = [[NSMutableArray alloc] init];

    [arr addObject:jsonDictionary];
    [self.socket emit:@"close" with:arr];
    self.closeFlag = YES;
    [self saveDocuments:self.documents];
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

@end
