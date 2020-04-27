/**

*

* @brief Collaboration Chatting View

* @details 콜라보레이션 채팅을 할 수있는 화면이다.

* @author kimjunghwan

* @date 2020/03/30

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
#import "ChatViewController.h"
#import "Masonry.h"
#import "UIImageView+WebCache.h"
#import "OverlayViewController.h"
#import "InviteViewController.h"
#import <SendBirdSDK/SendBirdSDK.h>

@interface ChatViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) UILabel *label;
@property (nonatomic) UIButton *button;
@property (nonatomic) double width;
@property (nonatomic) double height;

@property (nonatomic, nullable) UILabel *userTextView;
@property (nonatomic, nullable) UIView *chatUiView;
@property (nonatomic, nullable) UIView *stackView;
@property (strong, nonatomic) UITapGestureRecognizer *tapOutsideRecognizer;

@property (strong,nonatomic) UITableView *table;
@property (strong,nonatomic) NSArray *userArray;
@property (strong,nonatomic) NSArray *tableData;
@property (strong,nonatomic) NSMutableArray *userInfo;

@end

@implementation ChatViewController

#pragma mark - UIViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // size initial
    self.width = self.topController.view.frame.size.width * 0.29;
    self.height = self.topController.view.frame.size.height * 0.76;
    
    UIColor *defaultColor = [self colorWithHexString:@"#00d82b" alpha:1];
    self.tableData = [NSArray arrayWithObjects:@"Apple", @"Banana", @"Car", @"Dogdddddfadfsaefwefasdfawefawefdsfdfewfewfeasdfawefawdfsdfwefasdfsdfsdfdf", @"Elephantgggggejepfowjefpowejfpwoefjlskdfjlskdfjepofjwpeofjsldkfjsepfowjeflkwejf", nil];
    // 전체 view
    UIView *framUiView = [[UIView alloc] init];
    [self.view addSubview:framUiView];
    UIEdgeInsets padding = UIEdgeInsetsMake(self.width * 0.059, self.width * 0.059, self.width * 0.034, self.width * 0.059);

    [framUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(padding.top); //with is an optional semantic filler
        make.left.equalTo(self.view.mas_left).with.offset(padding.left);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-padding.bottom);
        make.right.equalTo(self.view.mas_right).with.offset(-padding.right);
    }];
    
    // bar
    UIImageView *barImage = [[UIImageView alloc] init];
    [barImage setImage:[PSPDFKitGlobal imageNamed:@"Rectangle"]];
    [framUiView addSubview:barImage];
    
    [barImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(framUiView);
        make.width.equalTo(@(self.width * 0.17));
        make.height.equalTo(@(self.height * 0.0038));
    }];
    
    // top
    UIView *topUiView = [[UIView alloc] init];
    [framUiView addSubview:topUiView];
    [topUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(barImage.mas_bottom).with.offset(self.height * 0.038);
        make.width.equalTo(@(self.width * 0.88));
        make.height.equalTo(@(self.height * 0.029));
    }];
    
    UILabel *collaboTextView = [[UILabel alloc] init];
    collaboTextView.textColor = defaultColor;
    [collaboTextView setText:@"Chatting"];
    [topUiView addSubview:collaboTextView];
    [collaboTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(self.width * 0.31));
    }];
    
    UIImageView *closeImage = [[UIImageView alloc] init];
    [closeImage setImage:[PSPDFKitGlobal imageNamed:@"close-collabo"]];
    [topUiView addSubview:closeImage];
    [closeImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(topUiView.mas_trailing);
        make.width.equalTo(@(self.width * 0.037));
        make.height.equalTo(@(self.width * 0.037));
        make.centerY.equalTo(topUiView);
    }];
    
    // chat
    self.chatUiView = [[UIView alloc] init];
    self.chatUiView.backgroundColor = [UIColor whiteColor];
    [framUiView addSubview:self.chatUiView];
    [self.chatUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topUiView.mas_bottom).with.offset(self.height * 0.038);
        make.height.equalTo(@(self.height * 0.75));
        make.width.equalTo(@(self.width * 0.88));
        make.centerX.equalTo(framUiView);
    }];

    CGRect tableFrame = CGRectMake(0, 0, self.width * 0.88, self.height * 0.75);
    self.table = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    self.table.rowHeight = UITableViewAutomaticDimension;
    self.table.estimatedRowHeight = self.height * 0.1;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.backgroundColor = [UIColor blackColor];
    self.table.allowsSelection = false;
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.chatUiView addSubview:self.table];
    
    // bottom
    self.bottomUiView = [[UIView alloc] init];
    self.bottomUiView.backgroundColor = [self colorWithHexString:@"#b4b4b4" alpha:1];
    self.bottomUiView.layer.cornerRadius = 8;
    self.bottomUiView.layer.masksToBounds = true;
    [framUiView addSubview:self.bottomUiView];
    [self.bottomUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(framUiView.mas_bottom);
        make.centerX.equalTo(framUiView);
        make.width.equalTo(@(self.width * 0.93));
        make.height.equalTo(@(self.height * 0.055));
    }];
    
    self.editField = [[UITextField alloc] init];
    self.editField.delegate = self;
    self.editField.userInteractionEnabled = YES;
    [self.bottomUiView addSubview:self.editField];
    [self.editField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomUiView.mas_leading).with.offset(self.width * 0.04);
        make.width.equalTo(@(self.width * 0.75));
        make.height.equalTo(@(self.height * 0.04));
        make.centerY.equalTo(self.bottomUiView);
    }];

    self.sendButton = [[UIButton alloc] init];
    [self.sendButton setImage:[PSPDFKitGlobal imageNamed:@"chatting_send"] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomUiView addSubview:self.sendButton];
    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.bottomUiView.mas_trailing).with.offset(-(self.width * 0.04));
        make.width.equalTo(@(self.width * 0.075));
        make.height.equalTo(@(self.width * 0.075));
        make.centerY.equalTo(self.bottomUiView);
    }];
    
    // close 버튼 눌렀을때 이벤트
    UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeButton)];
    closeTap.numberOfTapsRequired = 1;
    [closeImage setUserInteractionEnabled:YES];
    [closeImage addGestureRecognizer:closeTap];
    
    UIPanGestureRecognizer *moveView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleView:)];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.userInteractionEnabled = YES;
    self.view.layer.cornerRadius = 8;
    self.view.layer.masksToBounds = true;
    
    [self.view addGestureRecognizer:moveView];
    
    self.view.frame = CGRectMake(self.topController.view.frame.size.width * 0.64, self.topController.view.frame.size.height * 0.09, self.width, self.height);
}

#pragma mark - Chatting Table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [self.table dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // profile image set
    UIImageView *profileImageView = [[UIImageView alloc] init];
    [profileImageView setImage:[PSPDFKitGlobal imageNamed:@"default_profile"]];
    [cell addSubview:profileImageView];
    [profileImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.mas_top).with.offset(self.height * 0.008);
        make.width.equalTo(@(self.width * 0.13));
        make.height.equalTo(@(self.width * 0.13));
    }];
    
//    // massege box set
//    UIImageView *bubbleYouView = [[UIImageView alloc] init];
//    [bubbleYouView setImage:[PSPDFKitGlobal imageNamed:@"speech_bubble_you"]];
//    [cell addSubview:bubbleYouView];
//    [bubbleYouView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(nameTextView.mas_bottom).with.offset(self.height * 0.012);
//        make.width.equalTo(@(self.width * 0.04));
//        make.height.equalTo(@(self.width * 0.04));
//    }];
    
    // masseage part ui set
    UIView *masseageUIView = [[UIView alloc] init];
    [cell addSubview:masseageUIView];
    
    // name set
    UILabel *nameTextView = [[UILabel alloc] init];
    nameTextView.text = @"kimjunghwan";
    nameTextView.textColor = [self colorWithHexString:@"#b4b4b4" alpha:1];
    [masseageUIView addSubview:nameTextView];
    [nameTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(masseageUIView.mas_top);
        make.width.equalTo(@(self.width * 0.5));
        make.height.equalTo(@(self.height * 0.024));
    }];
    
    // massege text set
    UILabel *receiveLabel = [[UILabel alloc] init];
    receiveLabel.text = [self.tableData objectAtIndex:indexPath.row];
    receiveLabel.textColor = [UIColor whiteColor];
    receiveLabel.layer.masksToBounds = YES;
    receiveLabel.layer.cornerRadius = 7.0;
    [masseageUIView addSubview:receiveLabel];

    receiveLabel.numberOfLines = 0;
    receiveLabel.backgroundColor = [self colorWithHexString:@"#2676e1" alpha:1];
    CGSize constraint = CGSizeMake(250,9999);
    
    CGSize size = [receiveLabel.text sizeWithFont:[UIFont systemFontOfSize:20]
    constrainedToSize:constraint
        lineBreakMode:UILineBreakModeWordWrap];
    
    [receiveLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameTextView.mas_bottom).with.offset(self.height * 0.01);
        make.width.equalTo(@(size.width));
        make.height.equalTo(@(size.height));
    }];
    
    self.table.rowHeight = size.height + 30 + self.height * 0.024;
    [masseageUIView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(profileImageView.mas_right).with.offset(self.height * 0.012);
        make.width.equalTo(@(self.width * 0.7));
        make.height.equalTo(@(size.height + 30 + self.height * 0.024));
    }];
    
    cell.backgroundColor = [UIColor blackColor];
    return cell;
}
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"title of cell %@", [self.tableData objectAtIndex:indexPath.row]);
}

#pragma mark - Gesture Recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void)handleView:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    
    [recognizer setTranslation:CGPointZero inView:self.view];
}

#pragma mark - Begin Editing
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSLog(@"single Tap on textFieldDidChange %@", self.editField.text);
    self.bottomUiView.backgroundColor = [UIColor whiteColor];
    [self.sendButton setImage:[PSPDFKitGlobal imageNamed:@"chatting_act_send"] forState:UIControlStateNormal];
    return YES;
}

#pragma mark - Message Send
- (void)sendMessage{
    if (self.editField.editing) {
        NSLog(@"send message %@", self.editField.text);
        self.editField.text = @"";
    }
}

#pragma mark - Close Chatting View
- (void)closeButton{
    NSLog(@"single Tap on imageview");
//    [SBDGroupChannel getChannelWithUrl:@"1584082798992Collabo161951" completionHandler:^(SBDGroupChannel * _Nullable channel, SBDError * _Nullable error) {
//        if (error != nil) { // Error.
//            return;
//        }
//        NSLog(@"single Tap on openChannel");
//        [channel sendUserMessage:@"MESSAGE" data:@"DATA" customType:@"url_preview" completionHandler:^(SBDUserMessage * _Nullable userMessage, SBDError * _Nullable error) {
//            if (error != nil) { // Error.
//                return;
//            }
//        }];
//    }];
    [self.view removeFromSuperview];
    self.openCollabo = FALSE;
}

#pragma mark - Hex -> rgb Color Convert Method
- (UIColor *)colorWithHexString:(NSString *)str_HEX  alpha:(CGFloat)alpha_range{
    NSString *noHashString = [str_HEX stringByReplacingOccurrencesOfString:@"#" withString:@""]; // remove the #

    int red = 0;
    int green = 0;
    int blue = 0;

    if ([str_HEX length]<=3)
    {
        sscanf([noHashString UTF8String], "%01X%01X%01X", &red, &green, &blue);
        return  [UIColor colorWithRed:red/16.0 green:green/16.0 blue:blue/16.0 alpha:alpha_range];
    }
    else if ([str_HEX length]>7)
    {
        NSString *mySmallerString = [noHashString substringToIndex:6];
        sscanf([mySmallerString UTF8String], "%02X%02X%02X", &red, &green, &blue);
        return  [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha_range];
    }
    else
    {
        sscanf([noHashString UTF8String], "%02X%02X%02X", &red, &green, &blue);
        return  [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha_range];
    }
}

@end
