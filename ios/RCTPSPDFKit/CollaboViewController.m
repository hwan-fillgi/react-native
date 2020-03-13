//
//  CollaboViewController.m
//  AppAuth
//
//  Created by kim junghwan on 2020/02/19.
//
#import "PSCCustomUserInterfaceView.h"
#import "RCTPSPDFKitView.h"
#import <React/RCTUtils.h>
#import "RCTConvert+PSPDFAnnotation.h"
#import "RCTConvert+PSPDFViewMode.h"
#import "RCTConvert+UIBarButtonItem.h"
#import "RCTConvert+PSPDFConfiguration.h"
#import "RCTPSPDFKitViewManager.h"
#import "CollaboViewController.h"
#import "Masonry.h"
#import "UIImageView+WebCache.h"

@interface CollaboViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic) UILabel *label;
@property (nonatomic) UITextField *textField;
@property (nonatomic) UIButton *button;
@property (nonatomic) double width;
@property (nonatomic) double height;

@property (nonatomic, nullable) UILabel *userTextView;
@property (nonatomic, nullable) UIView *listUiView;
@property (nonatomic, nullable) UIView *stackView;
@property (nonatomic, nullable) UIImage *closeImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapOutsideRecognizer;

@property (strong,nonatomic) UITableView *table;
@property (strong,nonatomic) NSArray *content;
@property (strong,nonatomic) NSArray *userArray;
@property (strong,nonatomic) NSArray *tableData;

@end

@implementation CollaboViewController

#pragma mark - UIViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *superView = [[UIView alloc] init];
    NSLog(@"noteId %@", self.noteId);
    [self loadMember];
    self.content = @[ @"Monday", @"Tuesday", @"Wednesday",@"Thursday",@"Friday",@"Saturday",@"Sunday"];
    // size initial
    self.width = self.topController.view.frame.size.width * 0.29;
    self.height = self.topController.view.frame.size.height * 0.8;
    
    //전체 view
    UIView *framUiView = [[UIView alloc] init];
    [self.view addSubview:framUiView];
    UIEdgeInsets padding = UIEdgeInsetsMake(self.width * 0.059, self.width * 0.059, self.width * 0.059, self.width * 0.059);

    [framUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(padding.top); //with is an optional semantic filler
        make.left.equalTo(self.view.mas_left).with.offset(padding.left);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-padding.bottom);
        make.right.equalTo(self.view.mas_right).with.offset(-padding.right);
    }];
    //bar
    UIImageView *barImage = [[UIImageView alloc] init];
    [barImage setImage:[PSPDFKitGlobal imageNamed:@"Rectangle"]];
    barImage.backgroundColor = [UIColor redColor];
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
    }];
    
    UILabel *collaboTextView = [[UILabel alloc] init];
    collaboTextView.textColor = [UIColor redColor];
    [collaboTextView setText:@"Collaboration"];
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
    self.userTextView.textColor = [UIColor redColor];
    NSString *number = [@(self.userArray.count) stringValue];
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
    
    //invite
    UIView *inviteUiView = [[UIView alloc] init];
    [framUiView addSubview:inviteUiView];
    [inviteUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topUiView.mas_bottom).with.offset(self.height * 0.038);
        make.left.equalTo(framUiView.mas_left).with.offset(self.width * 0.011);
        make.height.equalTo(@(self.width * 0.15));
    }];
    
    UIImageView *inviteImage = [[UIImageView alloc] init];
    [inviteImage setImage:[PSPDFKitGlobal imageNamed:@"invite-collabo"]];
    [inviteUiView addSubview:inviteImage];
    [inviteImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(self.width * 0.15));
        make.height.equalTo(@(self.width * 0.15));
    }];
    
    UILabel *inviteTextView = [[UILabel alloc] init];
    inviteTextView.textColor = [UIColor redColor];
    [inviteTextView setText:@"invite"];
    [inviteUiView addSubview:inviteTextView];
    [inviteTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(inviteImage.mas_right).with.offset(self.width * 0.065);
        make.centerY.equalTo(inviteUiView);
    }];
    
    //list
    self.listUiView = [[UIView alloc] init];
    self.listUiView.backgroundColor = [UIColor whiteColor];
    [framUiView addSubview:self.listUiView];
    [self.listUiView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(inviteUiView.mas_bottom).with.offset(self.height * 0.038);
        make.left.equalTo(framUiView.mas_left).with.offset(self.width * 0.011);
        make.height.equalTo(@(self.height * 0.7));
        make.width.equalTo(@(self.width * 0.88));
    }];

    CGRect tableFrame = CGRectMake(0, 0, self.width * 0.88, self.height * 0.7);
    self.table = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    self.table.rowHeight = self.height * 0.1;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.table.showsVerticalScrollIndicator = NO;
//    self.table.showsHorizontalScrollIndicator = NO;
    self.table.backgroundColor = [UIColor blackColor];
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.listUiView addSubview:self.table];
    
    UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    closeTap.numberOfTapsRequired = 1;
    [closeImage setUserInteractionEnabled:YES];
    [closeImage addGestureRecognizer:closeTap];
    
    UIPanGestureRecognizer *moveView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleView:)];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.userInteractionEnabled = YES;
    self.view.layer.cornerRadius = 8;
    self.view.layer.masksToBounds = true;
    
    [self.view addGestureRecognizer:moveView];
    
    NSLog(@"noteId %f", self.topController.view.frame.size.width);
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topController.view);
        make.width.equalTo(@(self.width));
        make.height.equalTo(@(self.height));
    }];
}

- (void)loadMember {
    NSLog(@"load member");
    // 기본 구성에 URLSession 생성
    NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];
    // request URL 설정
    NSURL *document_url = [NSURL URLWithString:@"https://1g3h2oj5z6.execute-api.us-west-1.amazonaws.com/prod/users/collabo_user"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:document_url];
    
    // UTF8 인코딩을 사용하여 POST 문자열 매개 변수를 데이터로 변환
    NSString *postParams = [NSString stringWithFormat:@"note_id=%@", self.noteId];
    NSData *documentData = [postParams dataUsingEncoding:NSUTF8StringEncoding];

    // 셋
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:documentData];

    // dataTask 생성
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data!=nil)
        {
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSLog(@"json data %@", json);
            if([[json objectForKey:@"result"] isEqualToString:@"success"]){
                NSLog(@"success");
                NSLog(@"json data %@", [json objectForKey:@"data"]);
                
                // Convert to JSON object:
                self.userArray = [NSJSONSerialization JSONObjectWithData:[[json objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding]
                                                                      options:0 error:NULL];
                NSLog(@"jsonObject=%@", self.userArray);

                // Extract "username" values:
                self.tableData = [self.userArray valueForKey:@"username"];
                NSLog(@"tableData=%@", self.tableData);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.table reloadData];
                    NSString *number = [@(self.userArray.count) stringValue];
                    [self.userTextView setText:number];
                    [self.userTextView setNeedsDisplay];
                });
                
            }
        } else {
            NSLog(@"error");
        }
    }];
    [dataTask resume];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.userArray.count;
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [self.table dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
    }
    //UIImage *image = [PSPDFKitGlobal imageNamed:@"invite-collabo"];
    NSString *imageString = [[self.userArray objectAtIndex:indexPath.row] valueForKey:@"profile_img"];
    NSLog(@"imageString=%@", imageString);
    if (imageString == nil || [imageString isEqual:[NSNull null]]) {
        [cell.imageView setImage:[PSPDFKitGlobal imageNamed:@"default_profile"]];
        cell.imageView.layer.cornerRadius = (self.width * 0.15) / 2;
        cell.imageView.layer.borderWidth = 2.0;
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.borderColor = [[UIColor redColor] CGColor];
    } else {
        NSURL *imageUrl = [NSURL URLWithString:imageString];
        [cell.imageView sd_setImageWithURL:imageUrl placeholderImage:[PSPDFKitGlobal imageNamed:@"default_profile"]];
        cell.imageView.layer.cornerRadius = (self.width * 0.15) / 2;
        cell.imageView.layer.borderWidth = 2.0;
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.borderColor = [[UIColor redColor] CGColor];
        //[cell.imageView sd_setImageWithURL:imageUrl];
    }
    [cell.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(cell.mas_leading);
        make.width.equalTo(@(self.width * 0.15));
        make.height.equalTo(@(self.width * 0.15));
    }];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text =  [[self.userArray objectAtIndex:indexPath.row] valueForKey:@"username"];
    cell.textLabel.textColor = [UIColor whiteColor];
    [cell.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(cell.imageView.mas_right).with.offset(self.width * 0.065);
        make.centerY.equalTo(cell.imageView);
    }];
    cell.backgroundColor = [UIColor blackColor];
    return cell;
}
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"title of cell %@", [[self.userArray objectAtIndex:indexPath.row] valueForKey:@"username"]);
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

- (void)closeView{
    NSLog(@"single Tap on imageview");
    [self.view removeFromSuperview];
    self.openCollabo = FALSE;
}

@end

