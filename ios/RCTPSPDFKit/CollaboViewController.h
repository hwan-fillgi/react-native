//
//  CollaboViewController.h
//  Pods
//
//  Created by kim junghwan on 2020/02/19.
//

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;

@interface CollaboViewController : UIViewController

@property (nonatomic, nullable) PSPDFViewController *pdfController;
@property (nonatomic, nullable) UIViewController *topController;
@property (nonatomic) BOOL openCollabo;
@property (nonatomic, nullable) NSString *noteId;

@end
