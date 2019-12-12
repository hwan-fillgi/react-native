//
//  Copyright © 2018-2019 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

#import "RCTConvert+PSPDFAnnotationToolbarConfiguration.h"

@implementation RCTConvert (PSPDFAnnotationToolbarConfiguration)

+ (PSPDFAnnotationToolbarConfiguration *)PSPDFAnnotationToolbarConfiguration:(id)json {
  NSArray *itemsToParse = [RCTConvert NSArray:json];
  NSMutableArray *parsedItems = [NSMutableArray arrayWithCapacity:itemsToParse.count];
  for (id itemToParse in itemsToParse) {
    if ([itemToParse isKindOfClass:[NSDictionary class]]) {
      NSDictionary *dict = itemToParse;
      NSArray *subArray = dict[@"items"];
      NSMutableArray *subItems = [NSMutableArray arrayWithCapacity:subArray.count];
      for (id subItem in subArray) {
        if (subItem) {
          PSPDFAnnotationString annotationString = [RCTConvert PSPDFAnnotationStringFromName:subItem];
          PSPDFAnnotationGroupItemConfigurationBlock configurationBlock = ^UIImage *(PSPDFAnnotationGroupItem *item, id container, UIColor *tintColor){
              return [[RCTConvert configureBlockImage:subItem] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
          };
          [subItems addObject:[PSPDFAnnotationGroupItem itemWithType:annotationString variant:@"" configurationBlock:configurationBlock]];
          //[subItems addObject:[PSPDFAnnotationGroupItem itemWithType:annotationString]];
        }
      }
      [parsedItems addObject:[PSPDFAnnotationGroup groupWithItems:subItems]];
    } else {
        NSLog(@"aaaaa: %@",itemToParse);
      PSPDFAnnotationString annotationString = [RCTConvert PSPDFAnnotationStringFromName:itemToParse];
        NSLog(@"aaaaa: %@",annotationString);
      if (annotationString) {
        PSPDFAnnotationGroupItemConfigurationBlock configurationBlock = ^UIImage *(PSPDFAnnotationGroupItem *item, id container, UIColor *tintColor){
            return [[RCTConvert configureBlockImage:itemToParse] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        };
        [parsedItems addObject:[PSPDFAnnotationGroup groupWithItems:@[[PSPDFAnnotationGroupItem itemWithType:annotationString variant:@"" configurationBlock:configurationBlock]]]];
      }
    }
  }
  return  [[PSPDFAnnotationToolbarConfiguration alloc] initWithAnnotationGroups:parsedItems];
}

+ (UIImage *)configureBlockImage:(NSString *)name {
    NSLog(@"aa: %@",name);
    UIImage *image;
    if([name isEqualToString:@"link"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"highlight"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"strikeout"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"underline"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"squiggly"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"note"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_note"];
    }else if([name isEqualToString:@"freetext"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_text"];
    }else if([name isEqualToString:@"ink"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"square"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-rectangle"];
    }else if([name isEqualToString:@"circle"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-ellipse"];
    }else if([name isEqualToString:@"line"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-line"];
    }else if([name isEqualToString:@"polygon"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-polygon"];
    }else if([name isEqualToString:@"polyline"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-polyline"];
    }else if([name isEqualToString:@"signature"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_signiture"];
    }else if([name isEqualToString:@"stamp"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"eraser"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_eraser"];
    }else if([name isEqualToString:@"widget"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_pen"];
    }else if([name isEqualToString:@"image"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_picture"];
    }else if([name isEqualToString:@"selectiontool"]){
        image = [PSPDFKitGlobal imageNamed:@"icon_lasso"];
    }else if([name isEqualToString:@"highlighter"]){
        NSLog(@"highlighter");
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-highlight"];
    }else if([name isEqualToString:@"arrow"]){
        NSLog(@"arrow");
        image = [PSPDFKitGlobal imageNamed:@"icon_pen-highlight"];
    }
    return image;
}

+ (PSPDFAnnotationString)PSPDFAnnotationStringFromName:(NSString *)name {
  
  static NSDictionary *nameToAnnotationStringMapping;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableDictionary *mapping = [[NSMutableDictionary alloc] init];
    
    [mapping setValue:PSPDFAnnotationStringLink forKeyPath:@"link"];
    [mapping setValue:PSPDFAnnotationStringHighlight forKeyPath:@"highlight"];
    [mapping setValue:PSPDFAnnotationMenuStrikeout forKeyPath:@"strikeout"];
    [mapping setValue:PSPDFAnnotationStringUnderline forKeyPath:@"underline"];
    [mapping setValue:PSPDFAnnotationMenuSquiggle forKeyPath:@"squiggly"];
    [mapping setValue:PSPDFAnnotationStringNote forKeyPath:@"note"];
    [mapping setValue:PSPDFAnnotationStringFreeText forKeyPath:@"freetext"];
    [mapping setValue:PSPDFAnnotationStringInk forKeyPath:@"ink"];
    [mapping setValue:PSPDFAnnotationStringSquare forKeyPath:@"square"];
    [mapping setValue:PSPDFAnnotationStringCircle forKeyPath:@"circle"];
    [mapping setValue:PSPDFAnnotationStringLine forKeyPath:@"line"];
    [mapping setValue:PSPDFAnnotationStringPolygon forKeyPath:@"polygon"];
    [mapping setValue:PSPDFAnnotationStringPolyLine forKeyPath:@"polyline"];
    [mapping setValue:PSPDFAnnotationStringSignature forKeyPath:@"signature"];
    [mapping setValue:PSPDFAnnotationStringStamp forKeyPath:@"stamp"];
    [mapping setValue:PSPDFAnnotationStringEraser forKeyPath:@"eraser"];
    [mapping setValue:PSPDFAnnotationStringSound forKeyPath:@"sound"];
    [mapping setValue:PSPDFAnnotationStringImage forKeyPath:@"image"];
    [mapping setValue:PSPDFAnnotationStringRedaction forKeyPath:@"redaction"];
    [mapping setValue:PSPDFAnnotationStringSelectionTool forKeyPath:@"selectiontool"];
    [mapping setValue:PSPDFAnnotationVariantStringInkHighlighter forKeyPath:@"highlighter"];
    [mapping setValue:PSPDFAnnotationVariantStringLineArrow forKey:@"arrow"];
    
    nameToAnnotationStringMapping = [[NSDictionary alloc] initWithDictionary:mapping];
  });
  
  return nameToAnnotationStringMapping[name];
}

@end
