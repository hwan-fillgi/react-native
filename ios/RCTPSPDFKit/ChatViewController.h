/**

*

* @brief 채팅화면

* @details 내부에서 아무짓도 안한다.

* @author kimjunghwan

* @date 2020/03/30

* @version 0.0.1

*

*/

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;

@interface ChatViewController : UIViewController

@property (nonatomic, nullable) PSPDFViewController *pdfController;
@property (nonatomic, nullable) UIViewController *topController;
@property (nonatomic) BOOL openCollabo;
@property (nonatomic, nullable) NSString *noteId;
@property (nonatomic, nullable) NSString *username;
@property (nonatomic, nullable) NSString *profileImage;
@property (nonatomic, nullable) NSString *userId;

@property (nonatomic, nullable) UITextField *editField;
@property (nonatomic, nullable) UIView *bottomUiView;
@property (nonatomic, nullable) UIButton *sendButton;

@end
