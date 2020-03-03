//
//  Copyright © 2018-2019 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <React/RCTViewManager.h>
#import "OverlayViewController.h"

@import Instant;
@import SocketIO;
@interface RCTPSPDFKitViewManager : RCTViewManager

@property(nonatomic, nullable) NSString *version;
@property (nonatomic, strong) PSPDFInstantClient *instantClient;
@property(nonatomic, assign) BOOL rightPdf;
@property (nonatomic, nullable) NSString *document_id;
@property (nonatomic, nullable) id<PSPDFInstantDocumentDescriptor> instantDescriptor;
@property (nonatomic, nullable) NSString* JWT;
@property (nonatomic, nullable) NSString* noteId;
@property (nonatomic, nullable) OverlayViewController *overlayViewController;
@property (nonatomic, nullable) NSNumber *mynumber;
@property (nonatomic, nullable) SocketIOClient *socket;
 
+(RCTPSPDFKitViewManager *) theSettingsData;

@end

