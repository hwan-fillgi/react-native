/**

*

* @brief 초대화면

* @details 

* @author kimjunghwan

* @date 2020/02/09

* @version 0.0.1

*

*/

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;

@interface CollaboViewController : UIViewController

@property (nonatomic, nullable) PSPDFViewController *pdfController;
@property (nonatomic, nullable) UIViewController *topController;
@property (nonatomic) BOOL openCollabo;
@property (nonatomic, nullable) NSString *noteId;
@property (nonatomic, nullable) NSString *username;
@property (nonatomic, nullable) NSString *profileImage;
@property (nonatomic, nullable) NSString *userId;

@end
