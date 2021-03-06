/**

 *

 * @brief 초대화면 리스트

 * @details 사람들을 검색해서 초대할수있다.

 * @author kimjunghwan

 * @date 2020/03/17

 * @version 0.0.1

 *

 */


#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@import PSPDFKit;
@import PSPDFKitUI;

@interface InviteViewController : UIViewController

@property (nonatomic, nullable) PSPDFViewController *pdfController;
@property (nonatomic, nullable) UIViewController *topController;
@property (nonatomic, nullable) UIView *topUiView;
@property (nonatomic) BOOL openCollabo;
@property (nonatomic, nullable) NSString *noteId;
@property (nonatomic, nullable) NSString *username;
@property (nonatomic, nullable) NSString *profileImage;
@property (nonatomic, nullable) NSString *userId;

@end

