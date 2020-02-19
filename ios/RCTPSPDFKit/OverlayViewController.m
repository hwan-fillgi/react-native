//
//  OverlayViewController.m
//  AppAuth
//
//  Created by kim junghwan on 2020/02/14.
//
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

    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button.translatesAutoresizingMaskIntoConstraints = NO;
    [self.button setTitle:@"Unlock" forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.button sizeToFit];
    [self.button addTarget:self action:@selector(unlock:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.label, self.textField, self.button]];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.spacing = 20;
    [self.view addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.widthAnchor constraintEqualToConstant:300],
        [stackView.heightAnchor constraintEqualToConstant:150],
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
    UIColor *backgroundColor = [UIColor redColor];

    switch (state) {
        case PSPDFControllerStateDefault:
            backgroundColor = nil;
            break;

        case PSPDFControllerStateEmpty:
            text = @"No document set";
            break;

        case PSPDFControllerStateLoading:
            text = @"Loading...";
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
