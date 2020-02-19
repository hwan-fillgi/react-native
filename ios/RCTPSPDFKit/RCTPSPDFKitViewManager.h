//
//  Copyright © 2018-2019 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import <React/RCTViewManager.h>
#import "Instant.h"

@interface RCTPSPDFKitViewManager : RCTViewManager

@property(nonatomic, strong) NSString *version;
@property (nonatomic, strong) PSPDFInstantClient *instantClient;
@property(nonatomic, assign) BOOL rightPdf;

 

+(RCTPSPDFKitViewManager *) theSettingsData;

@end

