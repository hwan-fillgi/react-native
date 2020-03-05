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

@interface CollaboViewController () <UIGestureRecognizerDelegate>

@property (nonatomic) UILabel *label;
@property (nonatomic) UITextField *textField;
@property (nonatomic) UIButton *button;

@property (nonatomic, nullable) UIView *stackView;
@property (nonatomic, nullable) UIImage *closeImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapOutsideRecognizer;

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
    
    self.view.frame = CGRectMake(0, 0, 350, 600);
    self.view.backgroundColor = [UIColor redColor];
    self.view.userInteractionEnabled = YES;
    self.view.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    
    [self.view addGestureRecognizer:moveView];
    
    [self.view addSubview:self.stackView];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.tapOutsideRecognizer) {
        self.tapOutsideRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
        self.tapOutsideRecognizer.numberOfTapsRequired = 1;
        self.tapOutsideRecognizer.cancelsTouchesInView = NO;
        self.tapOutsideRecognizer.delegate = self;
        [self.view.window addGestureRecognizer:self.tapOutsideRecognizer];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // to avoid nasty crashes
    if (self.tapOutsideRecognizer) {
        [self.view.window removeGestureRecognizer:self.tapOutsideRecognizer];
        self.tapOutsideRecognizer = nil;
    }
}

#pragma mark - Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window

        //Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.

        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil])
        {
            // Remove the recognizer first so it's view.window is valid.
            [self.view.window removeGestureRecognizer:sender];
            [self close:sender];
        }
    }
}

#pragma mark - Gesture Recognizer
// because of iOS8
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void)handleView:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)closeView{
    NSLog(@"single Tap on imageview");
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

