//
//  ViewController.m
//  RSVedioRecorder
//
//  Created by SOTSYS024 on 13/02/17.
//  Copyright © 2017 Rahul. All rights reserved.
//

#import "ViewController.h"
#import "RSVideoRecorderController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    RSVideoRecorderController *video = [[RSVideoRecorderController alloc] init];
    [video setCompletion:^(NSURL* url, BOOL seccess) {
        NSLog(@"%d",seccess);
    }];
    [self presentViewController:video animated:true completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
