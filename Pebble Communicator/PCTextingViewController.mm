//
//  PCFirstViewController.m
//  Pebble Communicator
//
//  Created by Riley Testut on 4/11/13.
//  Copyright (c) 2013 Testut Tech. All rights reserved.
//

#import "PCTextingViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <id3/tag.h>

@interface PCTextingViewController () <AVAudioPlayerDelegate>

@property (strong, nonatomic) NSMutableArray *filenameArray;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation PCTextingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self resetAudioFileDirectory];
}

- (void)viewDidAppear: (BOOL) animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                NSLog(@"Enter");
                break;
                
            case UIEventSubtypeRemoteControlPause:
                NSLog(@"Enter");
                break;
                
            default:
                break;
        }
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
