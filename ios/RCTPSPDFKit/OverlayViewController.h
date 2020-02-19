//
//  OverlayViewController.h
//  Pods
//
//  Created by kim junghwan on 2020/02/14.
//
#import <PSPDFKitUI/PSPDFUserInterfaceView.h>
#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;

@interface OverlayViewController : UIViewController <PSPDFControllerStateHandling>

@property (nonatomic, nullable) PSPDFViewController *pdfController;

@end
