/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/ImageTarget.h>


#import "VideoPlaybackEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"
#import "SampleMath.h"
#import "Quad.h"

#import "VideoPlaybackAppDelegate.h"

//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the QCAR camera, which causes QCAR to locate our EAGLView and start
//    the render thread.
// 3) QCAR calls our renderFrameQCAR method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


namespace {
    // --- Data private to this unit ---
    // Augmentation model scale factor
    const float kObjectScale = 3.0f;
    
    // Texture filenames (an Object3D object is created for each texture)
    const char* textureFilenames[NUM_AUGMENTATION_TEXTURES] = {
        "icon_play.png",
        "icon_loading.png",
        "icon_error.png",
        "a1.png",
        "a2.png",
        "a3.png",
        "a4.png",
        "a5.png",
		"a6.png",
        "a7.png",
        "a8.png",
        "a9.png",
        "a10.png",
		"a11.png",
        "a12.png",
        "a13.png",
        "a14.png",
        "a15.png",
		"a16.png",
        "a17.png",
        "a18.png",
        "a19.png",
        "a20.png",
		"a21.png",
        "a22.png",
        "a23.png",
        "a24.png",
        "a25.png",
		"a26.png",
        "a27.png",
        "a28.png",
        "a29.png",
        "a30.png",
 		"a31.png",
        "a32.png",
        "a33.png",
        "a34.png",
        "a35.png",
		"a36.png",
        "a37.png",
        "a38.png",
        "a39.png",
        "a40.png",
        "a41.png",
        "a42.png",
        "a43.png",
        "a44.png",
        "a45.png",
		"a46.png",
        "a47.png",
        "a48.png",
        "a49.png",
        "a50.png",
		"a51.png",
        "a52.png",
        "a53.png",
        "a54.png",
        "a55.png",
		"a56.png",
        "a57.png",
        "a58.png",
        "a59.png",
        "a60.png",
		"a61.png",
        "a62.png",
        "a63.png",
        "a64.png",
        "a65.png",
		"a66.png",
        "a67.png",
        "a68.png",
        "a69.png",
        "a70.png",
		"a71.png",
        "a72.png",
        "a73.png",
        "a74.png",
        "a75.png",
		"a76.png",
        "a77.png",
        "a78.png",
        "a79.png",
        "a80.png",
		"a81.png",
        "a82.png",
        "a83.png",
        "a84.png",
        "a85.png",
		"a86.png",
        "a87.png",
        "a88.png",
        "a89.png",
        "a90.png",
		"a91.png",
        "a92.png",
        "a93.png",
        "a94.png",
        "a95.png",
		"a96.png",
        "a97.png",
        "a98.png",
        "a99.png",
        "a100.png"
    };
    
    enum tagObjectIndex {
        OBJECT_PLAY_ICON,
        OBJECT_BUSY_ICON,
        OBJECT_ERROR_ICON,
        OBJECT_KEYFRAME_1,
        OBJECT_KEYFRAME_2,
    };
    
    const NSTimeInterval DOUBLE_TAP_INTERVAL = 0.3f;
    const NSTimeInterval TRACKING_LOST_TIMEOUT = 2.0f;
    
    // Playback icon scale factors
    const float SCALE_ICON = 2.0f;
    const float SCALE_ICON_TRANSLATION = 1.98f;
    
    // Video quad texture coordinates
    const GLfloat videoQuadTextureCoords[] = {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    
    struct tagVideoData {
        // Needed to calculate whether a screen tap is inside the target
        QCAR::Matrix44F modelViewMatrix;
        
        // Trackable dimensions
        QCAR::Vec2F targetPositiveDimensions;
        
        // Currently active flag
        BOOL isActive;
    } videoData[NUM_VIDEO_TARGETS];
    
    int touchedTarget = 0;
    
    BOOL alertShowing=NO;
    MPMoviePlayerController *theMoviPlayer;
    UIAlertView *alert;
    //  QCARControl *control;
    BOOL longPressed=NO,isplayingFullscreen=NO;
    
}


@interface VideoPlaybackEAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end


@implementation VideoPlaybackEAGLView
@synthesize scrollForVideo,imageforbutton;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame rootViewController:(VideoPlaybackViewController *) rootViewController appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        videoPlaybackViewController = rootViewController;
        
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:2.0f];
        }
        
        // Load the augmentation textures
        for (int i = 0; i < [[VideoPlaybackAppDelegate sharedInstance].arrayForTargetImage count]; ++i) {
            // abhi 0==i
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
//            augmentationTexture[i] = [[Texture alloc] init];
        }

        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
            
            // Set appropriate texture parameters (for NPOT textures)
            if (OBJECT_KEYFRAME_1 <= i) {
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
        }

        [self initShaders];
        
       // scrollForVideo =[[UIScrollView alloc]initWithFrame:CGRectMake(0,0, 50, frame.size.height)];

        scrollForVideo =[[UIScrollView alloc]initWithFrame:CGRectMake(0,[UIScreen mainScreen].bounds.size.height-50, [UIScreen mainScreen].bounds.size.width,50)];
        [scrollForVideo setBackgroundColor:[UIColor redColor]];
        
        [self addSubview:scrollForVideo];
        
        [self bringSubviewToFront:scrollForVideo];
        
        xforbutton=0;
        tagforbutton=1000;
    }
    
    return self;
}
    
- (void) prepare {
    // For each target, create a VideoPlayerHelper object and zero the
    // target dimensions
    // For each target, create a VideoPlayerHelper object and zero the
    // target dimensions
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        videoPlayerHelper[i] = [[VideoPlayerHelper alloc] initWithRootViewController:videoPlaybackViewController];
        videoData[i].targetPositiveDimensions.data[0] = 0.0f;
        videoData[i].targetPositiveDimensions.data[1] = 0.0f;
    }
    
    // Start video playback from the current position (the beginning) on the
    // first run of the app
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        videoPlaybackTime[i] = VIDEO_PLAYBACK_CURRENT_POSITION;
    }
    
    // For each video-augmented target
    for (int i = 0; i < [[VideoPlaybackAppDelegate sharedInstance].arrayForVideoUrl count]; ++i) {
        // Load a local file for playback and resume playback if video was
        // playing when the app went into the background
        VideoPlayerHelper* player = [self getVideoPlayerHelper:i];
              
        NSString* filename=[NSString stringWithFormat:@"%@",[[VideoPlaybackAppDelegate sharedInstance].arrayForVideoUrl objectAtIndex:i]];
        
        /* abghi hide code
        
         NSString* filename;
         
         switch (i) {
         case 0:
         filename = @"VuforiaSizzleReel_1.m4v";
         break;
         default:
         filename = @"VuforiaSizzleReel_2.m4v";
         break;
         }
         
         */
        
        if (NO == [player load:filename playImmediately:NO fromPosition:videoPlaybackTime[i]]) {
            NSLog(@"Failed to load media");
        }
    }
    
    
}
    
- (void) dismiss {
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        [videoPlayerHelper[i] unload];
        [videoPlayerHelper[i] release];
        videoPlayerHelper[i] = nil;
    }
}

- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];

    for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
        [augmentationTexture[i] release];
    }
    
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        [videoPlayerHelper[i] release];
    }
    [super dealloc];
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

//------------------------------------------------------------------------------
#pragma mark - User interaction

- (bool) handleTouchPoint:(CGPoint) point {
    // Store the current touch location
    touchLocation_X = point.x;
    touchLocation_Y = point.y;
    
    // Determine which target was touched (if no target was touch, touchedTarget
    // will be -1)
    touchedTarget = [self tapInsideTargetWithID];
    
    // Ignore touches when videoPlayerHelper is playing in fullscreen mode
    if (-1 != touchedTarget && PLAYING_FULLSCREEN != [videoPlayerHelper[touchedTarget] getStatus]) {
        // Get the state of the video player for the target the user touched
        MEDIA_STATE mediaState = [videoPlayerHelper[touchedTarget] getStatus];
        
        // If any on-texture video is playing, pause it
        for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
            if (PLAYING == [videoPlayerHelper[i] getStatus]) {
                [videoPlayerHelper[i] pause];
            }
        }
        
#ifdef EXAMPLE_CODE_REMOTE_FILE
        // With remote files, single tap starts playback using the native player
        if (ERROR != mediaState && NOT_READY != mediaState) {
            // Play the video
            NSLog(@"Playing video with native player");
            [videoPlayerHelper[touchedTarget] play:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        }
#else
        // For the target the user touched
        if (ERROR != mediaState && NOT_READY != mediaState && PLAYING != mediaState) {
            // Play the video
            NSLog(@"Playing video with on-texture player");
            [videoPlayerHelper[touchedTarget] play:NO fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        }
#endif
        return true;
    } else {
        return false;
    }
}
- (void) preparePlayers {
    [self prepare];
}


- (void) dismissPlayers {
    [self dismiss];
}


- (bool) handleDoubleTouchPoint:(CGPoint) point {
    // Store the current touch location
    touchLocation_X = point.x;
    touchLocation_Y = point.y;
    
    // Determine which target was touched (if no target was touch, touchedTarget
    // will be -1)
    touchedTarget = [self tapInsideTargetWithID];
    
    if (-1 != touchedTarget) {
        if (PLAYING_FULLSCREEN != [videoPlayerHelper[touchedTarget] getStatus]) {
            MEDIA_STATE mediaState = [videoPlayerHelper[touchedTarget] getStatus];
            
            if (ERROR != mediaState && NOT_READY != mediaState) {
                // Play the video
                NSLog(@"Playing video with native player");
                [videoPlayerHelper[touchedTarget] play:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
            }
            
            // If any on-texture video is playing, pause it
            for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
                if (PLAYING == [videoPlayerHelper[i] getStatus]) {
                    [videoPlayerHelper[i] pause];
                }
            }
        }

        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"show_menu" object:self];
    }

    return true;
}

// Determine whether a screen tap is inside the target
- (int)tapInsideTargetWithID
{
    QCAR::Vec3F intersection, lineStart, lineEnd;
    // Get the current projection matrix
    QCAR::Matrix44F projectionMatrix = [vapp projectionMatrix];
    QCAR::Matrix44F inverseProjMatrix = SampleMath::Matrix44FInverse(projectionMatrix);
    CGRect rect = [self bounds];
    int touchInTarget = -1;
    
    // ----- Synchronise data access -----
    [dataLock lock];
    
    // The target returns as pose the centre of the trackable.  Thus its
    // dimensions go from -width / 2 to width / 2 and from -height / 2 to
    // height / 2.  The following if statement simply checks that the tap is
    // within this range
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        SampleMath::projectScreenPointToPlane(inverseProjMatrix, videoData[i].modelViewMatrix, rect.size.width, rect.size.height,
                                              QCAR::Vec2F(touchLocation_X, touchLocation_Y), QCAR::Vec3F(0, 0, 0), QCAR::Vec3F(0, 0, 1), intersection, lineStart, lineEnd);
        
        if ((intersection.data[0] >= -videoData[i].targetPositiveDimensions.data[0]) && (intersection.data[0] <= videoData[i].targetPositiveDimensions.data[0]) &&
            (intersection.data[1] >= -videoData[i].targetPositiveDimensions.data[1]) && (intersection.data[1] <= videoData[i].targetPositiveDimensions.data[1])) {
            // The tap is only valid if it is inside an active target
            if (YES == videoData[i].isActive) {
                touchInTarget = i;
                break;
            }
        }
    }
    
    [dataLock unlock];
    // ----- End synchronise data access -----
    
    return touchInTarget;
}
    
// Get a pointer to a VideoPlayerHelper object held by this EAGLView
- (VideoPlayerHelper*)getVideoPlayerHelper:(int)index
{
    return videoPlayerHelper[index];
}







//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Begin QCAR rendering for this frame, retrieving the tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    
    // Render the video background
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    
    // We must detect if background reflection is active and adjust the culling
    // direction.  If the reflection is active, this means the pose matrix has
    // been reflected as well, therefore standard counter clockwise face culling
    // will result in "inside out" models
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON) {
        // Front camera
        glFrontFace(GL_CW);
    }
    else {
        // Back camera
        glFrontFace(GL_CCW);
    }
    
    // Get the active trackables
    int numActiveTrackables = state.getNumTrackableResults();
    
    // ----- Synchronise data access -----
    [dataLock lock];
    
    // Assume all targets are inactive (used when determining tap locations)
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        videoData[i].isActive = NO;
    }
    
    // Did we find any trackables this frame?
    for (int i = 0; i < numActiveTrackables; ++i) {
        // Get the trackable
        const QCAR::TrackableResult* trackableResult = state.getTrackableResult(i);
        const QCAR::ImageTarget& imageTarget = (const QCAR::ImageTarget&) trackableResult->getTrackable();
        
        /*ABHI
         // VideoPlayerHelper to use for current target
        int playerIndex = 0;    // stones
        
        if (strcmp(imageTarget.getName(), "chips") == 0)
        {
            playerIndex = 1;
        }
        */
        // Mark this video (target) as active
        
        for (int i=0; i<[[VideoPlaybackAppDelegate sharedInstance].arrayForImageTarget count]; i++) {
            
            NSString *strSQL = [[NSString alloc]initWithString:[[VideoPlaybackAppDelegate sharedInstance].arrayForTargetImage objectAtIndex:i]];
            const char *bar = [strSQL UTF8String];
            
            if (strcmp(imageTarget.getName(), bar) == 0)
            {
                playerIndex = i;
                
                videoData[playerIndex].isActive = YES;
            }
            
        }
        int abhicheck=0;
        
        
                    NSArray *arrayforSubviews=self.scrollForVideo.subviews;
            
            //            for (UIView *imageviewSubview in arrayforSubviews)
            //            {
            //                if([imageviewSubview isKindOfClass:[UIImageView class]])
            //                {
            //                    [imageviewSubview removeFromSuperview];
            //                }
            //            }
            
            for (UIButton *buttonForSubview in arrayforSubviews)
            {
                    if(buttonForSubview.tag==playerIndex)
                    {
                        NSLog(@"this button already added!!!!");
                        abhicheck=1;
                    }
                
            }
        
            
            if(abhicheck==0)
            {
                // button=[UIButton buttonWithType:UIButtonTypeCustom];
                AsyncImageView *button=[[AsyncImageView alloc]init];
                [button addTarget:self action:@selector(videoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressTap:)];
                [button addGestureRecognizer:longPress];
                [button setBackgroundColor:[UIColor greenColor]];
                [button setFrame:CGRectMake(xforbutton, 0, 50, 50)];
                [button setTag:playerIndex];
                [button loadImage:[[VideoPlaybackAppDelegate sharedInstance].arrayForImageUrl objectAtIndex:playerIndex]];
                xforbutton+=50;

                [scrollForVideo performSelectorOnMainThread:@selector(addSubview:) withObject:button waitUntilDone:YES];
                               
            }
            
        
        
        if(xforbutton>[UIScreen mainScreen].bounds.size.width)
            [self.scrollForVideo setContentSize:CGSizeMake(xforbutton,50)];
        
        if(xforbutton<[UIScreen mainScreen].bounds.size.width)
            [self.scrollForVideo setContentSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 50)];
        
        videoData[playerIndex].isActive = YES;
        
        // Get the target size (used to determine if taps are within the target)
        if (0.0f == videoData[playerIndex].targetPositiveDimensions.data[0] ||
            0.0f == videoData[playerIndex].targetPositiveDimensions.data[1]) {
            const QCAR::ImageTarget& imageTarget = (const QCAR::ImageTarget&) trackableResult->getTrackable();
            
            videoData[playerIndex].targetPositiveDimensions = imageTarget.getSize();
            // The pose delivers the centre of the target, thus the dimensions
            // go from -width / 2 to width / 2, and -height / 2 to height / 2
            videoData[playerIndex].targetPositiveDimensions.data[0] /= 2.0f;
            videoData[playerIndex].targetPositiveDimensions.data[1] /= 2.0f;
        }
        
        // Get the current trackable pose
        const QCAR::Matrix34F& trackablePose = trackableResult->getPose();
        
        // This matrix is used to calculate the location of the screen tap
        videoData[playerIndex].modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(trackablePose);
        
        float aspectRatio;
        const GLvoid* texCoords;
        GLuint frameTextureID;
        BOOL displayVideoFrame = YES;
        
        // Retain value between calls
        static GLuint videoTextureID[NUM_VIDEO_TARGETS] = {0};
        
        MEDIA_STATE currentStatus = [videoPlayerHelper[playerIndex] getStatus];
        
        // NSLog(@"MEDIA_STATE for %d is %d", playerIndex, currentStatus);
        
        // --- INFORMATION ---
        // One could trigger automatic playback of a video at this point.  This
        // could be achieved by calling the play method of the VideoPlayerHelper
        // object if currentStatus is not PLAYING.  You should also call
        // getStatus again after making the call to play, in order to update the
        // value held in currentStatus.
        // --- END INFORMATION ---
        
        switch (currentStatus) {
            case PLAYING: {
                // If the tracking lost timer is scheduled, terminate it
                if (nil != trackingLostTimer) {
                    // Timer termination must occur on the same thread on which
                    // it was installed
                    [self performSelectorOnMainThread:@selector(terminateTrackingLostTimer) withObject:nil waitUntilDone:YES];
                }
                
                // Upload the decoded video data for the latest frame to OpenGL
                // and obtain the video texture ID
                GLuint videoTexID = [videoPlayerHelper[playerIndex] updateVideoData];
                
                if (0 == videoTextureID[playerIndex]) {
                    videoTextureID[playerIndex] = videoTexID;
                }
                
                // Fallthrough
            }
            case PAUSED:
                if (0 == videoTextureID[playerIndex]) {
                    // No video texture available, display keyframe
                    displayVideoFrame = NO;
                }
                else {
                    // Display the texture most recently returned from the call
                    // to [videoPlayerHelper updateVideoData]
                    frameTextureID = videoTextureID[playerIndex];
                }
                
                break;
                
            default:
                videoTextureID[playerIndex] = 0;
                displayVideoFrame = NO;
                break;
        }
        
        if (YES == displayVideoFrame) {
            // ---- Display the video frame -----
            aspectRatio = (float)[videoPlayerHelper[playerIndex] getVideoHeight] / (float)[videoPlayerHelper[playerIndex] getVideoWidth];
            texCoords = videoQuadTextureCoords;
        }
        else {
            // ----- Display the keyframe -----
            Texture* t = augmentationTexture[OBJECT_KEYFRAME_1 + playerIndex];
            frameTextureID = [t textureID];
            aspectRatio = (float)[t height] / (float)[t width];
            texCoords = quadTexCoords;
        }
        
        // Get the current projection matrix
        QCAR::Matrix44F projMatrix = vapp.projectionMatrix;
        
        // If the current status is valid (not NOT_READY or ERROR), render the
        // video quad with the texture we've just selected
        if (NOT_READY != currentStatus) {
            // Convert trackable pose to matrix for use with OpenGL
            QCAR::Matrix44F modelViewMatrixVideo = QCAR::Tool::convertPose2GLMatrix(trackablePose);
            QCAR::Matrix44F modelViewProjectionVideo;
            
//            SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, videoData[playerIndex].targetPositiveDimensions.data[0],
//                                             &modelViewMatrixVideo.data[0]);
            
            SampleApplicationUtils::scalePoseMatrix(videoData[playerIndex].targetPositiveDimensions.data[0],
                                         videoData[playerIndex].targetPositiveDimensions.data[0] * aspectRatio,
                                         videoData[playerIndex].targetPositiveDimensions.data[0],
                                         &modelViewMatrixVideo.data[0]);
            
            SampleApplicationUtils::multiplyMatrix(projMatrix.data,
                                        &modelViewMatrixVideo.data[0] ,
                                        &modelViewProjectionVideo.data[0]);
            
            glUseProgram(shaderProgramID);
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, frameTextureID);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionVideo.data[0]);
            glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, quadIndices);
            
            glDisableVertexAttribArray(vertexHandle);
            glDisableVertexAttribArray(normalHandle);
            glDisableVertexAttribArray(textureCoordHandle);
            
            glUseProgram(0);
        }
        
        // If the current status is not PLAYING, render an icon
        if (PLAYING != currentStatus) {
            GLuint iconTextureID;
            
            switch (currentStatus) {
                case READY:
                case REACHED_END:
                case PAUSED:
                case STOPPED: {
                    // ----- Display play icon -----
                    iconTextureID = [augmentationTexture[OBJECT_PLAY_ICON] textureID];
                    break;
                }
                    
                case ERROR: {
                    // ----- Display error icon -----
                    iconTextureID = [augmentationTexture[OBJECT_ERROR_ICON] textureID];
                    break;
                }
                    
                default: {
                    // ----- Display busy icon -----
                    iconTextureID = [augmentationTexture[OBJECT_BUSY_ICON] textureID];
                    break;
                }
            }
            
            // Convert trackable pose to matrix for use with OpenGL
            QCAR::Matrix44F modelViewMatrixButton = QCAR::Tool::convertPose2GLMatrix(trackablePose);
            QCAR::Matrix44F modelViewProjectionButton;
            
            //SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON_TRANSLATION, &modelViewMatrixButton.data[0]);
            SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, 5.0f, &modelViewMatrixButton.data[0]);
            
            SampleApplicationUtils::scalePoseMatrix(videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                         videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                         videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                         &modelViewMatrixButton.data[0]);
            
            SampleApplicationUtils::multiplyMatrix(projMatrix.data,
                                        &modelViewMatrixButton.data[0] ,
                                        &modelViewProjectionButton.data[0]);
            
            glDepthFunc(GL_LEQUAL);
            
            glUseProgram(shaderProgramID);
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, quadTexCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            // Blend the icon over the background
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, iconTextureID);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionButton.data[0] );
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, quadIndices);
            
            glDisable(GL_BLEND);
            
            glDisableVertexAttribArray(vertexHandle);
            glDisableVertexAttribArray(normalHandle);
            glDisableVertexAttribArray(textureCoordHandle);
            
            glUseProgram(0);
            
            glDepthFunc(GL_LESS);
        }
        
        SampleApplicationUtils::checkGlError("VideoPlayback renderFrameQCAR");
    }
    
    // --- INFORMATION ---
    // One could pause automatic playback of a video at this point.  Simply call
    // the pause method of the VideoPlayerHelper object without setting the
    // timer (as below).
    // --- END INFORMATION ---
    
    // If a video is playing on texture and we have lost tracking, create a
    // timer on the main thread that will pause video playback after
    // TRACKING_LOST_TIMEOUT seconds
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        if (nil == trackingLostTimer && NO == videoData[i].isActive && PLAYING == [videoPlayerHelper[i] getStatus]) {
            [self performSelectorOnMainThread:@selector(createTrackingLostTimer) withObject:nil waitUntilDone:YES];
            break;
        }
    }
    
    [dataLock unlock];
    // ----- End synchronise data access -----
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];

}

// Create the tracking lost timer
- (void)createTrackingLostTimer
{
    trackingLostTimer = [NSTimer scheduledTimerWithTimeInterval:TRACKING_LOST_TIMEOUT target:self selector:@selector(trackingLostTimerFired:) userInfo:nil repeats:NO];
}


// Terminate the tracking lost timer
- (void)terminateTrackingLostTimer
{
    [trackingLostTimer invalidate];
    trackingLostTimer = nil;
}


// Tracking lost timer fired, pause video playback
- (void)trackingLostTimerFired:(NSTimer*)timer
{
    // Tracking has been lost for TRACKING_LOST_TIMEOUT seconds, pause playback
    // (we can safely do this on all our VideoPlayerHelpers objects)
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        [videoPlayerHelper[i] pause];
    }
    trackingLostTimer = nil;
}


//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"Simple.fragsh"];

    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#pragma mark draging gesture methods
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    CGPoint translation = [panRecognizer translationInView:self];
    CGPoint imageViewPosition = theMoviPlayer.view.center;
    imageViewPosition.x += translation.x;
    imageViewPosition.y += translation.y;
    
    theMoviPlayer.view.center = imageViewPosition;
    [panRecognizer setTranslation:CGPointZero inView:self];
}

- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
    CGFloat scale = pinchRecognizer.scale;
    theMoviPlayer.view.transform = CGAffineTransformScale(theMoviPlayer.view.transform, scale, scale);
    pinchRecognizer.scale = 1.0;
}

- (void)rotationDetected:(UIRotationGestureRecognizer *)rotationRecognizer
{
    CGFloat angle = rotationRecognizer.rotation;
    theMoviPlayer.view.transform = CGAffineTransformRotate(theMoviPlayer.view.transform, angle);
    rotationRecognizer.rotation = 0.0;
}


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                    #pragma mark button action methods
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


- (IBAction)videoButtonPressed:(UIButton*)sender
{
    @try
    {
        
        
        NSLog(@"#####videoButtonPressed#####");
        
        theMoviPlayer = [[MPMoviePlayerController alloc] init];
        
        NSURL *movieURL = [NSURL URLWithString:[[VideoPlaybackAppDelegate sharedInstance].arrayForVideoUrl objectAtIndex:sender.tag]];
        
        theMoviPlayer.contentURL=movieURL;
       // theMoviPlayer.controlStyle = MPMovieControlStyleFullscreen;
        theMoviPlayer.controlStyle = MPMovieControlStyleFullscreen;
              
        
        [theMoviPlayer.view setBackgroundColor:[UIColor clearColor]];
        if(IS_IPAD)
        {
            [theMoviPlayer.view setFrame:CGRectMake(0, 572, 400, 400)];
        }
        else if(IS_IPHONE)
        {
            if (IS_IPHONE5)
            {
                [theMoviPlayer.view setFrame:CGRectMake(100, 315, 200, 200)];
            }
            else
                [theMoviPlayer.view setFrame:CGRectMake(100, 215, 200, 200)];
        }
//        [theMoviPlayer.view setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:)name:MPMoviePlayerPlaybackDidFinishNotification object:theMoviPlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:theMoviPlayer];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(movieLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:theMoviPlayer];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(MPMoviePlayerNowPlayingMovieDidChangeNotification:) name:MPMoviePlayerNowPlayingMovieDidChangeNotification object:theMoviPlayer];

        
        
        theMoviPlayer.view.userInteractionEnabled = YES;
        [self addSubview:theMoviPlayer.view];
        
        //  UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
        //  [theMoviPlayer.view addGestureRecognizer:panRecognizer];
        
        // UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
        // [theMoviPlayer.view addGestureRecognizer:pinchRecognizer];
        
        UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationDetected:)];
        [theMoviPlayer.view addGestureRecognizer:rotationRecognizer];
        
        
        UISwipeGestureRecognizer *oneFingerSwipeDown = [[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(oneFingerSwipeDown:)] autorelease];
        [oneFingerSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
        [theMoviPlayer.view addGestureRecognizer:oneFingerSwipeDown];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tapGesture.delegate=self;
        tapGesture.numberOfTapsRequired = 2;
        [theMoviPlayer.view addGestureRecognizer:tapGesture];
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        
        [theMoviPlayer play];
        [VideoPlaybackAppDelegate showHud:@"Loading..."];

        
    }@catch (NSException *e) {
        NSLog(@"Exception comes %@",e);
    }
}

- (void) movieLoadStateDidChange:(NSNotification*)notification
{
    [VideoPlaybackAppDelegate killHud];
}

- (void) moviePlayBackDidFinish:(NSNotification*)notification
{/*
    [theMoviPlayer stop];
    [theMoviPlayer.view removeFromSuperview];
    theMoviPlayer=nil;
  */
    theMoviPlayer = [notification object];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:theMoviPlayer];
    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    if (reason == MPMovieFinishReasonPlaybackEnded)
    {
        NSLog(@"MPMovieFinishReasonPlaybackEnded");
    }else if (reason == MPMovieFinishReasonUserExited)
    {
        NSLog(@"MPMovieFinishReasonUserExited");
    }else if (reason == MPMovieFinishReasonPlaybackError)
    {
        NSLog(@"%@",MPMoviePlayerPlaybackDidFinishReasonUserInfoKey);
        return;
    }

}
-(void)MPMoviePlayerNowPlayingMovieDidChangeNotification:(NSNotification*)notification{
    NSLog(@"PlyerNext");
}

-(void)oneFingerSwipeDown:(id)sender
{
    NSLog(@"swip call");
    
    CGPoint imageViewPosition = theMoviPlayer.view.center;
    imageViewPosition.y += 200;
    theMoviPlayer.view.center = imageViewPosition;
    [theMoviPlayer stop];
    [theMoviPlayer.view removeFromSuperview];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        NSLog(@"####################### Doubletap Detected #######################");
    }
    NSLog(@"####################### Doubletap Detected #######################");
    
    if(!isplayingFullscreen)
    {
        [theMoviPlayer.view setFrame:CGRectMake(0, 0,[[UIScreen mainScreen]bounds].size.width,[[UIScreen mainScreen]bounds].size.height)];
        isplayingFullscreen=YES;
    }
    else
    {
        if(IS_IPAD)
        {
            [theMoviPlayer.view setFrame:CGRectMake(0, 572, 400, 400)];
        }
        else if(IS_IPHONE)
        {
            if (IS_IPHONE5)
            {
                [theMoviPlayer.view setFrame:CGRectMake(100, 315, 200, 200)];
            }
            else
                [theMoviPlayer.view setFrame:CGRectMake(100, 215, 200, 200)];
        }
        isplayingFullscreen=NO;
        
    }
}

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                    #pragma mark Long Press Gesture
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-(void)longPressTap:(id)sender
{
   
    
    UIButton *button1 = (UIButton *)[sender view];
    selectedBtnTag=button1.tag;
    if(!alert)
    {
        alert=[[UIAlertView alloc]initWithTitle:@"Message" message:@"DO YOU WANNA DELETE BUTTON ?" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:@"DELETE", nil];
        [alert setFrame:CGRectMake(10, 10, 222, 222)];
        [alert show];
        alertShowing=YES;
    }
    
    
    //and you can also compare the frame of your button with recogniser's view
    
    
    //remember frame comparing is alternative method you dont need
    //to write frame comparing code if you are matching the tag number of button
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {

        NSLog(@"Cancel");
    }
    else if (buttonIndex == 1)
    {
        float xpos;
        NSLog(@"Delete");
        for (UIButton* Btn in [self.scrollForVideo subviews])
        {
            NSLog(@" selected btn tag is %d buttons tags is %d",selectedBtnTag,Btn.tag);
            if (Btn.tag==selectedBtnTag)
            {
                xpos=Btn.frame.origin.x;
                [Btn removeFromSuperview];
            }
        }
        for (UIButton* Btn in [self.scrollForVideo subviews])
        {
            if(xpos<Btn.frame.origin.x)
            {
                
                CGRect frameBtn=Btn.frame;
                frameBtn.origin.x-=50;
                [Btn setFrame:frameBtn];
            }
        }
        xforbutton-=50;
        if(xforbutton<0)
        {
            xforbutton=0;
        }
        if(xforbutton<[UIScreen mainScreen].bounds.size.width)
        [self.scrollForVideo setContentSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 50)];
    }
    alertShowing=NO;
    alert=nil;
}

#pragma mark - gesture delegate

// this allows you to dispatch touches
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}
// this enables you to handle multiple recognizers on single view
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


#pragma mark - MPMoviePlayer Notification

-(void)movieFinishedCallback:(NSNotification*)aNotification{
    
    
    [theMoviPlayer stop];
    [theMoviPlayer.view removeFromSuperview];
    
    theMoviPlayer=nil;
}

-(void)moviePlayerPlaybackStateChanged:(NSNotification *)notification {
    NSLog(@"Noti %@",notification);
    
    MPMoviePlayerController *moviePlayer = notification.object;
    MPMoviePlaybackState playbackState = moviePlayer.playbackState;
    switch (playbackState) {
        case MPMoviePlaybackStateStopped:
            NSLog(@"stop");
            break;
        case MPMoviePlaybackStatePlaying:
            NSLog(@"playing");
            break;
        case MPMoviePlaybackStatePaused:
            NSLog(@"paused");
            break;
        case MPMoviePlaybackStateInterrupted:
            NSLog(@"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            NSLog(@"forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            NSLog(@"backward");
            break;
        default:
            break;
    }
}


@end

