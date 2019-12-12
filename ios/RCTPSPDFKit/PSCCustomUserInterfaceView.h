#import <PSPDFKitUI/PSPDFUserInterfaceView.h>
#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;
@interface PSCCustomUserInterfaceView : PSPDFUserInterfaceView

@property (nonatomic, readonly) PSPDFViewController *pdfController;
@property (nonatomic, readonly) PSPDFWebViewController *webController;

@end
