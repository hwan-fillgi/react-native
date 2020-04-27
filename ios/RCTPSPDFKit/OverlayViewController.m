/**

*

* @brief pdf로딩 화면

* @details pdf가 로드될때 이 화면이 보여진다.
 
* @author kimjunghwan

* @date 2020/02/14

* @version 0.0.1

*

*/

#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTPSPDFKitViewManager.h"
#import "OverlayViewController.h"

@interface OverlayViewController ()

@property (nonatomic) UILabel *label;
@property (nonatomic) UITextField *textField;
@property (nonatomic) UIButton *button;
@property (nonatomic, retain) UIActivityIndicatorView *pageIndicator;

@end

@implementation OverlayViewController

#pragma mark - UIViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.label = [UILabel new];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.numberOfLines = 0;
    self.label.textColor = [UIColor blackColor];
    self.label.textAlignment = NSTextAlignmentCenter;

    self.textField = [UITextField new];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.secureTextEntry = YES;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.borderStyle = UITextBorderStyleRoundedRect;

    self.pageIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.pageIndicator setCenter:self.view.center];
    [self.pageIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.pageIndicator]];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.spacing = 20;
    [self.view addSubview:stackView];
    
    double width = [self.overlayWidth doubleValue];
    NSLog(@"awef %f", width);

    [NSLayoutConstraint activateConstraints:@[
        [stackView.widthAnchor constraintEqualToConstant:300],
        [stackView.heightAnchor constraintEqualToConstant:150],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:width],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

#pragma mark - Button Actions

- (void)unlock:(id)sender {
    NSString *password = self.textField.text;
    [self.document unlockWithPassword:password];
    [self.pdfController reloadData];
}

#pragma mark - PSPDFControllerStateHandling

@synthesize document;

-(void)setControllerState:(PSPDFControllerState)state error:(NSError *)error animated:(BOOL)animated {
    NSString *text = @"";
    UIColor *backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];

    switch (state) {
        case PSPDFControllerStateDefault:
            [self.pageIndicator stopAnimating];
            self.pageIndicator.hidden= TRUE;
            backgroundColor = nil;
            break;

        case PSPDFControllerStateEmpty:
            text = @"No document set";
            self.pageIndicator.hidden= FALSE;
            [self.pageIndicator startAnimating];
            break;

        case PSPDFControllerStateLoading:
            text = @"Loading...";
            self.pageIndicator.hidden= FALSE;
            [self.pageIndicator startAnimating];
            break;

        case PSPDFControllerStateLocked:
            text = @"Password:";
            break;

        case PSPDFControllerStateError:
            text = [NSString stringWithFormat:@"Unable to display document:\n%@", error.localizedDescription];
            break;

        default:
            break;
    }

    self.label.text = text;
    self.view.backgroundColor = backgroundColor;
    self.view.userInteractionEnabled = state != PSPDFControllerStateDefault;

    if (state == PSPDFControllerStateLocked) {
        self.textField.hidden = NO;
        self.button.hidden = NO;
        [self.textField becomeFirstResponder];
    } else {
        self.textField.hidden = YES;
        self.button.hidden = YES;
        [self.textField resignFirstResponder];
    }
}

@end
