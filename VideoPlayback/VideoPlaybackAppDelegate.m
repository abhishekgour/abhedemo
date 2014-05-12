/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import "VideoPlaybackAppDelegate.h"
#import "SampleAppAboutViewController.h"
#import "WebserviceOperation.h"
#import "WelcomeScreen.h"

//#import "SampleApplicationUtils.h"

HudView *hudView;

@implementation VideoPlaybackAppDelegate
@synthesize dictionaryForImageCacheing,arrayForImageUrl,arrayForVideoUrl,arrayForImageTarget,arrayForTargetImage;
- (void)dealloc
{
    [_window release];
    [super dealloc];
}
+(VideoPlaybackAppDelegate *)sharedInstance{
    return (VideoPlaybackAppDelegate*)[UIApplication sharedApplication].delegate;
}
-(void)getXmlContentHandler:(id)sender
{
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
  
    WebserviceOperation *service=[[WebserviceOperation alloc] initWithDelegate:self callback:nil];
    [service getZip];

//        NSString *documentsDirectory = [[NSBundle mainBundle] resourcePath];
//        NSString *documentsPath = [documentsDirectory stringByAppendingPathComponent:@"techvalensdemo.xml"];
//        
//        [sender writeToFile:documentsPath atomically:YES];
}

-(void)getAllURLHandler:(id)sender
{
    if ([sender isKindOfClass:[NSError class]])
    {
        
    }
    else{
        
      
        
        NSMutableDictionary *responseDic=(NSMutableDictionary*)sender;
        if (responseDic !=nil)
        {
            NSDictionary *dic=[responseDic valueForKey:@"NewDataSet"];
            
            NSArray *ResponseVideoURl=[dic objectForKey:@"Table1"];
            NSArray *ResponseImageURl=[dic objectForKey:@"Table2"];
            
            for (int i=0; i<[ResponseImageURl count]; i++)
            {
                [arrayForVideoUrl addObject:[[ResponseVideoURl objectAtIndex:i] valueForKey:@"Videofile_url"]];
                [arrayForImageUrl addObject:[[ResponseImageURl objectAtIndex:i] valueForKey:@"Name"]];
                
            }
      
            
            WebserviceOperation *service=[[WebserviceOperation alloc] initWithDelegate:self callback:@selector(getXmlContentHandler:)];
            [service getXmlContent];
            
          
            
        }
    }
    
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    dictionaryForImageCacheing=[[NSMutableDictionary alloc]init];
    arrayForImageUrl=[[NSMutableArray alloc]init];
    arrayForVideoUrl=[[NSMutableArray alloc]init];
    arrayForImageTarget=[[NSMutableArray alloc]init];
    arrayForTargetImage=[[NSMutableArray alloc]init];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    WelcomeScreen *welcome =[[WelcomeScreen alloc]init];
    [self.window setRootViewController:welcome];
    [self.window makeKeyAndVisible];
    
    WebserviceOperation *service=[[WebserviceOperation alloc] initWithDelegate:self callback:@selector(getAllURLHandler:)];
    [service getAllService];
    
    return YES;
}
-(void)allFix
{
   
//    arrayForTargetImage=[arrayForImageTarget sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    [arrayForTargetImage  addObjectsFromArray: [arrayForImageTarget sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    
    SampleAppAboutViewController *vc = [[[SampleAppAboutViewController alloc] initWithNibName:@"SampleAppAboutViewController" bundle:nil] autorelease];
    vc.appTitle = @"Video Playback";
    vc.appAboutPageName = @"VP_about";
    vc.appViewControllerClassName = @"VideoPlaybackViewController";
    
    UINavigationController * nc = [[UINavigationController alloc]initWithRootViewController:vc];
    nc.navigationBar.barStyle = UIBarStyleDefault;
    self.window.rootViewController = nc;
    
    
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark HUD Methods

+ (void)showHud:(NSString*)text
{
    if(hudView == nil)
    {
         hudView = [[HudView alloc]init];
        [hudView setUserInteractionEnabledForSuperview:[[UIApplication sharedApplication] keyWindow]];
        [hudView loadingViewInView:[[UIApplication sharedApplication] keyWindow] text:text];
        [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
    }
}

+ (void)killHud
{
    if(hudView != nil )
    {
        [hudView.loadingView removeFromSuperview];
        [hudView setUserInteractionEnabledForSuperview:[[UIApplication sharedApplication] keyWindow]];
        [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
        hudView = nil;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}
@end
