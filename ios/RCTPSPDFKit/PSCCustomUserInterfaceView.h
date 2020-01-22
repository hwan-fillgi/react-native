#import <PSPDFKitUI/PSPDFUserInterfaceView.h>
#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;
@interface PSCCustomUserInterfaceView : PSPDFUserInterfaceView

@property (nonatomic, readonly) PSPDFViewController *pdfController;
@property (nonatomic, readonly) PSPDFWebViewController *webController;
@property (nonatomic, readonly) PSPDFTabbedViewController *tabController;
@property (nonatomic, readonly) UINavigationController *navigationController;

@property (nonatomic, readonly) UIDocumentBrowserViewController *fileController;
@property (nonatomic, readonly) UIDocumentPickerViewController *filePickerController;
@property (nonatomic, readonly) UIViewController *rootViewController;
@property (nonatomic, strong) NSMutableArray *documents;
@property (nonatomic, nullable) NSString *noteId;

-(void)saveDocuments:(NSString *)noti;
@end

