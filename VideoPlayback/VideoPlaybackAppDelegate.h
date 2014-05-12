/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import <UIKit/UIKit.h>
#import "HudView.h"

@interface VideoPlaybackAppDelegate : UIResponder <UIApplicationDelegate,NSXMLParserDelegate>


@property (strong, nonatomic) UIWindow *window;

@property(strong,nonatomic)NSMutableDictionary *dictionaryForImageCacheing;
@property(strong,nonatomic) NSMutableArray *arrayForImageUrl;
@property(strong,nonatomic) NSMutableArray *arrayForVideoUrl;
@property(strong,nonatomic) NSMutableArray *arrayForImageTarget;
@property(strong,nonatomic) NSMutableArray *arrayForTargetImage;


//abhi methods
+(VideoPlaybackAppDelegate *)sharedInstance;
-(void)getAllURLHandler:(id)sender;

+ (void)killHud;
+ (void)showHud:(NSString*)text;

-(void)allFix;
@end
