//
//  RSVideoRecorderControllerViewController.h
//  RSVedioRecorder
//
//  Created by SOTSYS024 on 13/02/17.
//  Copyright © 2017 Rahul. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^vrCompletion)(NSURL* url, BOOL seccess);
@interface RSVideoRecorderController : UIViewController
@property (strong, nonatomic) vrCompletion completion;
@end
