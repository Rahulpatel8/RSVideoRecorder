//
//  ViewController.m
//  RSVedioRecorder
//
//  Created by SOTSYS024 on 13/02/17.
//  Copyright © 2017 Rahul. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVKit/AVKit.h>
#import "RSVideoRecorderController.h"
@interface ViewController () {
    BOOL isVideo;
}
@property NSURL *videoUrl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    if (!isVideo) {
        RSVideoRecorderController *video = [[RSVideoRecorderController alloc] init];
        [video setCompletion:^(NSURL* url, BOOL seccess) {
            if (seccess) {
                isVideo = true;
                self.videoUrl = url;
//                [self saveVideo];
                [self videoWithString:url];
            }
        }];
        [self presentViewController:video animated:true completion:nil];
    }
}

-(void)detectOrientation {
    NSLog(@"Orintation changed.");
}


-(void)videoWithString:(NSURL*)url {
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:url  options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, clipVideoTrack.timeRange.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
    CGSize videoSize;
    
    CGAffineTransform firstTransform = clipVideoTrack.preferredTransform;
    if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)  {
//        videoAssetOrientation_= UIImageOrientationRight; isVideoAssetPortrait_ = YES;
        videoSize= CGSizeMake([clipVideoTrack naturalSize].height, [clipVideoTrack naturalSize].width);
    }
    if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)  {
//        videoAssetOrientation_ =  UIImageOrientationLeft; isVideoAssetPortrait_ = YES;
        videoSize= CGSizeMake([clipVideoTrack naturalSize].height, [clipVideoTrack naturalSize].width);
    }
    if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)   {
        videoSize= [clipVideoTrack naturalSize];
    }
    if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0) {
        videoSize= [clipVideoTrack naturalSize];
    }
    
//    CALayer *parentLayer = [CALayer layer];
//    
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, videoSize.width,videoSize.height);
//    videoLayer.frame = CGRectMake(0, 0, videoSize.width,videoSize.height);
//   
//    
//    CATextLayer *titleLayer = [CATextLayer layer];
//    titleLayer.string = @"Text goes here";
//    titleLayer.font = CFBridgingRetain(@"Helvetica");
//    titleLayer.fontSize = 60;
//    titleLayer.backgroundColor = [[UIColor redColor] CGColor];
//    titleLayer.opacity = 0.5;
//    titleLayer.alignmentMode = kCAAlignmentCenter;
//    [titleLayer setFrame:CGRectMake(0, 0, videoSize.width, 100)]; //You may need to adjust this for proper display
//    [parentLayer addSublayer:titleLayer]; //ONLY IF WE ADDED TEXT
//     [parentLayer addSublayer:videoLayer];
    
    
    
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFont:@"Helvetica-Bold"];
    [subtitle1Text setFontSize:100];
    [subtitle1Text setFrame:CGRectMake(0, videoSize.height/2-100, videoSize.width, 200)];
    [subtitle1Text setString:@"Text goes here"];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    [subtitle1Text setBackgroundColor:[[UIColor redColor] CGColor]];
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    overlayLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:videoAsset];
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);

    AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    [firstlayerInstruction setTransform:firstTransform atTime:kCMTimeZero];
    videoComp.renderSize = videoSize;
    
    mainInstruction.layerInstructions = [NSArray arrayWithObject:firstlayerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.videoComposition = videoComp;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* VideoName = [NSString stringWithFormat:@"%@/mynewwatermarkedvideo.mp4",documentsDirectory];
    
    NSURL *exportUrl = [NSURL fileURLWithPath:VideoName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:VideoName])
    {
        [[NSFileManager defaultManager] removeItemAtPath:VideoName error:nil];
    }
    
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = exportUrl;
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self exportDidFinish:assetExport];
         });
     }
     ];
}



-(void)exportDidFinish:(AVAssetExportSession*)session
{
    NSURL *exportUrl = session.outputURL;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:exportUrl completionBlock:^(NSURL *assetURL, NSError *error)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (error) {
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 } else {
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                    delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 }
             });
         }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
