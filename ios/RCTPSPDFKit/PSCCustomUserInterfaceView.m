#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"

@implementation PSCCustomUserInterfaceView
- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    _pdfController = [[PSPDFViewController alloc] init];
    _pdfController.view.translatesAutoresizingMaskIntoConstraints = NO;
      
    NSURL *baseURL = [NSBundle.mainBundle URLForResource:@"youtube" withExtension:@"html"];
      
    _webController = [[PSPDFWebViewController alloc] initWithURL:baseURL];
    _webController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.webController.view];
      
    UIImageView *imageView = [[UIImageView alloc]init];
    [imageView setImage:[PSPDFKitGlobal imageNamed:@"scroll_bar"]];
    [imageView sizeToFit];
    imageView.userInteractionEnabled = YES;
    imageView.center = CGPointMake(self.webController.view.frame.size.width / 2, self.webController.view.frame.size.height / 2);
    [self addSubview:imageView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [imageView addGestureRecognizer:pan];
      
    [NSLayoutConstraint activateConstraints:
        @[[self.webController.view.topAnchor constraintEqualToAnchor:self.topAnchor constant:75],
        [self.webController.view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.webController.view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.webController.view.trailingAnchor constraintEqualToAnchor:imageView.centerXAnchor]
        ]];
  }
  return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + 0);

    [NSLayoutConstraint activateConstraints:
        @[[self.webController.view.trailingAnchor constraintEqualToAnchor:recognizer.view.centerXAnchor]
        ]];
    [recognizer setTranslation:CGPointZero inView:self];
    NSLog(@"asd: %f", translation.x);
    
    double f1 = recognizer.view.center.x + translation.x;
    NSNumber* num1 = [NSNumber numberWithDouble:f1];
    NSDictionary *notiDic=nil;
    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTime", nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytimes" object:nil userInfo:notiDic];
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

@end
