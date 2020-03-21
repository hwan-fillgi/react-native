//
//  InviteViewController.m
//  AppAuth
//
//  Created by kim junghwan on 2020/03/17.
//

#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTPSPDFKitViewManager.h"
#import "InviteViewController.h"
#import "Masonry.h"
#import "UIImageView+WebCache.h"
#import "OverlayViewController.h"

@interface InviteViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) UILabel *label;
@property (nonatomic) UITextField *searchField;
@property (nonatomic) UIButton *button;
@property (nonatomic) double width;
@property (nonatomic) double height;

@property (nonatomic, nullable) UILabel *userTextView;
@property (nonatomic, nullable) UIView *listUiView;
@property (nonatomic, nullable) UIView *stackView;
@property (strong, nonatomic) UITapGestureRecognizer *tapOutsideRecognizer;

@property (strong,nonatomic) UITableView *table;
@property (strong,nonatomic) NSArray *searchArray;
@property (strong,nonatomic) NSArray *tableData;
@property (strong,nonatomic) NSMutableArray *userInfo;
@property (strong,nonatomic) NSMutableArray *arrSelectionStatus;
@property (strong,nonatomic) UIImageView *checkImageView;
@property (strong,nonatomic) UITableViewCell *cell;

@end

@implementation InviteViewController

#pragma mark - UIViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // size initial
    self.width = self.topController.view.frame.size.width * 0.29;
    self.height = self.topController.view.frame.size.height * 0.8;
    
    UIColor *defaultColor = [self colorWithHexString:@"#00d82b" alpha:1];
    
    //전체 view
    UIView *framUiView = [[UIView alloc] init];
    [self.view addSubview:framUiView];
    UIEdgeInsets padding = UIEdgeInsetsMake(self.width * 0.059, self.width * 0.059, self.width * 0.059, self.width * 0.059);

    [framUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(padding.top); //with is an optional semantic filler
        make.left.equalTo(self.view.mas_left).with.offset(0);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-padding.bottom);
        make.right.equalTo(self.view.mas_right).with.offset(0);
    }];

    //bar
    UIImageView *barImage = [[UIImageView alloc] init];
    [barImage setImage:[PSPDFKitGlobal imageNamed:@"Rectangle"]];
    [framUiView addSubview:barImage];

    [barImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(framUiView);
        make.width.equalTo(@(self.width * 0.17));
        make.height.equalTo(@(self.height * 0.0038));
    }];
    
    //top
    UIView *topUiView = [[UIView alloc] init];
    [framUiView addSubview:topUiView];
    [topUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(barImage.mas_bottom).with.offset(self.height * 0.038);
        make.width.equalTo(@(self.width * 0.88));
        make.height.equalTo(@(self.height * 0.029));
        make.left.equalTo(self.view.mas_left).with.offset(padding.left);
        make.right.equalTo(self.view.mas_right).with.offset(-padding.right);
    }];

    UILabel *collaboTextView = [[UILabel alloc] init];
    collaboTextView.textColor = defaultColor;
    [collaboTextView setText:@"Invite"];
    [topUiView addSubview:collaboTextView];
    [collaboTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(self.width * 0.31));
    }];

    UIImageView *personImageView = [[UIImageView alloc] init];
    [personImageView setImage:[PSPDFKitGlobal imageNamed:@"person-collabo"]];
    [topUiView addSubview:personImageView];
    [personImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(collaboTextView.mas_right).with.offset(self.width * 0.3);
        make.width.equalTo(@(self.width * 0.037));
        make.height.equalTo(@(self.width * 0.037));
        make.centerY.equalTo(topUiView);
    }];

    self.userTextView = [[UILabel alloc] init];
    self.userTextView.textColor = defaultColor;
    NSString *number = [@(self.searchArray.count) stringValue];
    [self.userTextView setText:number];
    [topUiView addSubview:self.userTextView];
    [self.userTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(personImageView.mas_right).with.offset(self.width * 0.03);
        make.centerY.equalTo(topUiView);
    }];

    UILabel *slashTextView = [[UILabel alloc] init];
    slashTextView.textColor = [UIColor whiteColor];
    [slashTextView setText:@"/"];
    [topUiView addSubview:slashTextView];
    [slashTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.userTextView.mas_right).with.offset(self.width * 0.013);
        make.centerY.equalTo(topUiView);
    }];

    UILabel *defaultTextView = [[UILabel alloc] init];
    defaultTextView.textColor = [UIColor whiteColor];
    [defaultTextView setText:@"8"];
    [topUiView addSubview:defaultTextView];
    [defaultTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(slashTextView.mas_right).with.offset(self.width * 0.013);
        make.centerY.equalTo(topUiView);
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
    
    //line
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = [self colorWithHexString:@"#777777" alpha:1];
    [framUiView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topUiView.mas_bottom).with.offset(self.height * 0.032);
        make.left.equalTo(self.view.mas_left).with.offset(padding.left);
        make.right.equalTo(self.view.mas_right).with.offset(-padding.right);
        make.width.equalTo(@(self.width * 0.88));
        make.height.equalTo(@(3));
    }];
    
    //search
    UIView *searchView = [[UIView alloc] init];
    searchView.backgroundColor = [self colorWithHexString:@"#a8a8a8" alpha:1];
    searchView.layer.cornerRadius = 20;
    [framUiView addSubview:searchView];
    [searchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView.mas_bottom).with.offset(self.height * 0.038);
        make.left.equalTo(self.view.mas_left).with.offset(padding.left);
        make.right.equalTo(self.view.mas_right).with.offset(-padding.right);
        make.width.equalTo(@(self.width * 0.88));
        make.height.equalTo(@(self.height * 0.05));
    }];
    
    UIImageView *searchImage = [[UIImageView alloc] init];
    [searchImage setImage:[PSPDFKitGlobal imageNamed:@"colabo_search"]];
    [searchView addSubview:searchImage];
    [searchImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(searchView.mas_left).with.offset(self.width * 0.04);
        make.width.equalTo(@(self.width * 0.055));
        make.height.equalTo(@(self.width * 0.055));
        make.centerY.equalTo(searchView);
    }];
    
    self.searchField = [[UITextField alloc] init];
    self.searchField.placeholder = @"Search";
    [self.searchField addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    [searchView addSubview:self.searchField];
    [self.searchField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(searchImage.mas_right).with.offset(self.width * 0.04);
        make.width.equalTo(@(self.width * 0.67));
        make.height.equalTo(@(self.height * 0.037));
        make.centerY.equalTo(searchView);
    }];
    // Bottom border
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.height * 0.035, self.width * 0.67, 1.0f);
    bottomBorder.backgroundColor = [UIColor blackColor].CGColor;
    [self.searchField.layer addSublayer:bottomBorder];

    //list
    self.listUiView = [[UIView alloc] init];
    self.listUiView.backgroundColor = [UIColor redColor];
    [framUiView addSubview:self.listUiView];
    [self.listUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(searchView.mas_bottom).with.offset(self.height * 0.038);
        make.height.equalTo(@(self.height * 0.6));
        make.width.equalTo(@(self.width));
    }];
    
    CGRect tableFrame = CGRectMake(0, 0, self.width, self.height * 0.6);
    self.table = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    self.table.allowsMultipleSelection = YES;
    self.table.rowHeight = self.height * 0.1;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.backgroundColor = [UIColor blackColor];
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.listUiView addSubview:self.table];

    UIButton *inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    inviteButton.backgroundColor = defaultColor;
    inviteButton.layer.cornerRadius = 20;
    inviteButton.layer.masksToBounds = true;
    [inviteButton addTarget:self action:@selector(inviteButton) forControlEvents:UIControlEventTouchUpInside];
    [inviteButton setTitle:@"invite" forState:UIControlStateNormal];
    [framUiView addSubview:inviteButton];
    [inviteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.listUiView.mas_bottom).with.offset(self.height * 0.038);
        make.left.equalTo(self.view.mas_left).with.offset(padding.left);
        make.right.equalTo(self.view.mas_right).with.offset(-padding.right);
        make.centerX.equalTo(framUiView);
        make.height.equalTo(@(self.height * 0.05));
        make.width.equalTo(@(self.width * 0.53));
    }];
    
    // close 버튼 눌렀을때 이벤트
    UITapGestureRecognizer *beforeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beforeButton)];
    beforeTap.numberOfTapsRequired = 1;
    [closeImage setUserInteractionEnabled:YES];
    [closeImage addGestureRecognizer:beforeTap];
        
    self.view.backgroundColor = [UIColor blackColor];
    self.view.layer.cornerRadius = 8;
    self.view.layer.masksToBounds = true;
    
    self.view.frame = CGRectMake(0, 0, self.width, self.height);
}

// hex -> rgb color convert
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

- (void)searchMemberList:(NSString *)keyword {
    NSLog(@"search Member List");
    
    //get 방식일때
    NSString *getURL = [NSString stringWithFormat:@"%@/%@/%@/%@", @"https://1g3h2oj5z6.execute-api.us-west-1.amazonaws.com/prod/desk/collaboration/invitation", self.noteId, self.userId, keyword];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:getURL]];

    [request setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    if (data!=nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data options:kNilOptions error:&error];
        if([[json objectForKey:@"result"] isEqualToString:@"success"]){
            NSLog(@"success");
            // Convert to JSON object:
            NSLog(@"asdf %lu", [[json objectForKey:@"searchList"] count]);
            if ([[json objectForKey:@"searchList"] count] != 0) {
                NSLog(@"exist");
                NSLog(@"search array %@", [json objectForKey:@"searchList"]);
                self.searchArray = [json objectForKey:@"searchList"];
                
                // arrSelectionStatus holds the cell selection status
                self.arrSelectionStatus = [NSMutableArray array];
                for (int i=0; i<self.searchArray.count; i++) { //arrElements holds those elements which will be populated in tableview
                    [self.arrSelectionStatus addObject:[NSNumber numberWithBool:NO]];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.table reloadData];
                });
            }
        }
    } else{
        NSLog(@"error");
    }
    }] resume];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchArray.count;
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    self.cell = [self.table dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(self.cell == nil) {
        self.cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    // profile image set
    UIImageView *profileImageView = [[UIImageView alloc] init];
    NSString *imageString = [[self.searchArray objectAtIndex:indexPath.row] valueForKey:@"profile_img"];
    if (imageString == nil || [imageString isEqual:[NSNull null]]) {
        [profileImageView setImage:[PSPDFKitGlobal imageNamed:@"default_profile"]];
        profileImageView.layer.cornerRadius = (self.width * 0.15) / 2;
        profileImageView.layer.borderWidth = 2.0;
        profileImageView.layer.masksToBounds = YES;
        profileImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    } else {
        NSURL *imageUrl = [NSURL URLWithString:imageString];
        [profileImageView sd_setImageWithURL:imageUrl placeholderImage:[PSPDFKitGlobal imageNamed:@"default_profile"]];
        profileImageView.layer.cornerRadius = (self.width * 0.15) / 2;
        profileImageView.layer.borderWidth = 2.0;
        profileImageView.layer.masksToBounds = YES;
        profileImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    }
    [self.cell addSubview:profileImageView];
    [profileImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cell.mas_left).with.offset(self.width * 0.07);
        make.width.equalTo(@(self.width * 0.15));
        make.height.equalTo(@(self.width * 0.15));
        make.centerY.equalTo(self.cell);
    }];
    
    // username set
    self.cell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cell.textLabel.text =  [[self.searchArray objectAtIndex:indexPath.row] valueForKey:@"username"];
    self.cell.textLabel.textColor = [UIColor whiteColor];
    [self.cell.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(profileImageView.mas_right).with.offset(self.width * 0.065);
        make.width.equalTo(@(self.width * 0.5));
        make.centerY.equalTo(self.cell);
    }];
    
//    BOOL checked = [[item objectForKey:@"checked"] boolValue];
//    UIImage *image = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
    if([[tableView indexPathsForSelectedRows] containsObject:indexPath]) {
        [self.cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"colabo_checked"]];
    } else {
        [self.cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"colabo_unchecked"]];
    }
    // checkbox set
    self.checkImageView = [[UIImageView alloc] init];
    if ([[self.arrSelectionStatus objectAtIndex:indexPath.row] isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        [self.cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"colabo_unchecked"]];
    } else {
        [self.cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"colabo_checked"]];
    }
    //[self.cell addSubview:self.checkImageView];
    [self.cell.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        NSLog(@"aaaaaaa arr %@", self.arrSelectionStatus);
        make.left.equalTo(self.cell.textLabel.mas_right).with.offset(self.width * 0.065);
        make.width.equalTo(@(self.width * 0.06));
        make.height.equalTo(@(self.width * 0.06));
        make.centerY.equalTo(self.cell);
    }];
    
    self.cell.backgroundColor = [UIColor blackColor];
    // This is how you change the background color
    self.cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [self colorWithHexString:@"#777777" alpha:1];
    [self.cell setSelectedBackgroundView:bgColorView];
    
    NSLog(@"aaaaaaa arr %@", self.arrSelectionStatus);
    
    return self.cell;
}

// 로우 선택시 발생하는 이벤트
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"title of cell %@", [[self.searchArray objectAtIndex:indexPath.row] valueForKey:@"username"]);
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    [cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"colabo_checked"]];
    [self.arrSelectionStatus replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];
}

// 로우 선택 해제시 발생하는 이벤트
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    [cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"colabo_unchecked"]];
    [self.arrSelectionStatus replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:NO]];
}

#pragma mark - Gesture Recognizer
// because of iOS8
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void)handleView:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    
    [recognizer setTranslation:CGPointZero inView:self.view];
}


- (void)textFieldDidChange{
    NSLog(@"single Tap on textFieldDidChange %@", self.searchField.text);
    [self searchMemberList:self.searchField.text];
}

- (void)beforeButton{
    NSLog(@"single Tap on beforeButton");
    [self.view removeFromSuperview];
}

- (void)inviteButton{
    NSLog(@"single Tap on inviteButton");
}

@end
