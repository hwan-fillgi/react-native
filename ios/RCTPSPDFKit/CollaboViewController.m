//
//  CollaboViewController.m
//  AppAuth
//
//  Created by kim junghwan on 2020/02/19.
//
#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTPSPDFKitViewManager.h"
#import "CollaboViewController.h"

@interface CollaboViewController ()

@property (nonatomic) UILabel *label;
@property (nonatomic) UITextField *textField;
@property (nonatomic) UIButton *button;

@property (nonatomic, nullable) UIView *stackView;
@property (nonatomic, nullable) UIImage *closeImage;

@end

@implementation CollaboViewController

#pragma mark - UIViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.stackView = [[UIView alloc] init];
    self.stackView.frame = CGRectMake(0, 0, 350, 600);
    self.stackView.backgroundColor = [UIColor blackColor];
    self.stackView.userInteractionEnabled = YES;
    self.stackView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    
    UIImageView *closeImage = [[UIImageView alloc] init];
    [closeImage setImage:[PSPDFKitGlobal imageNamed:@"icon_getout"]];
    [closeImage sizeToFit];
    closeImage.backgroundColor = [UIColor redColor];
    [self.stackView addSubview:closeImage];
    
    UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    closeTap.numberOfTapsRequired = 1;
    [closeImage setUserInteractionEnabled:YES];
    [closeImage addGestureRecognizer:closeTap];
    
    UIPanGestureRecognizer *moveView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleView:)];
    [self.stackView addGestureRecognizer:moveView];
    
    [self.view addSubview:self.stackView];
}

- (void)handleView:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    
    [recognizer setTranslation:CGPointZero inView:self.view];
    
//    double f1 = recognizer.view.center.x + translation.x;
//    NSNumber* num1 = [NSNumber numberWithDouble:f1];
//    NSDictionary *notiDic=nil;
//    notiDic=[[NSDictionary alloc]initWithObjectsAndKeys:num1,@"playTime", nil];
//    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPlaytimes" object:nil userInfo:notiDic];
}

- (void)closeView{
    NSLog(@"single Tap on imageview");
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

