//
//  AsyncImageView.h
//  ScopeProject
//
//  Created by YOSHIDA Hiroyuki on 09/11/26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "VideoPlaybackAppDelegate.h"
@class HFHAppDelegate;

@interface AsyncImageView : UIButton {
@private
	NSURLConnection *connection;
	NSMutableData   *imageData;
	VideoPlaybackAppDelegate *delegate;
	NSMutableArray *arrayForURL;

	//ProgressBar
	UIProgressView *progressView;
	
	int totalfilesize;
	int filesizereceived;
	float filepercentage;
	
}

-(void) setimage:(UIImage*)image;
-(void)loadImage:(NSString *)url;
-(void)abort;

@end
