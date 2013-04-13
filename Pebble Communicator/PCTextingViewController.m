//
//  PCFirstViewController.m
//  Pebble Communicator
//
//  Created by Riley Testut on 4/11/13.
//  Copyright (c) 2013 Testut Tech. All rights reserved.
//

#import "PCTextingViewController.h"

#import "CKSMSService.h"
#import "CKConversation.h"
#import "CKSMSMessage.h"
#import "CKConversationList.h"
#import "CKSMSEntity.h"
#import "CKMessageStandaloneComposition.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MessageUI.h>

#define PEBBLE_MAX_CHARACTER_COUNT 29

@interface PCTextingViewController () <AVAudioPlayerDelegate> {
    NSInteger _characterIndex;
    NSInteger _fakeDiscNumber;
}

@property (copy, nonatomic) NSArray *characterArray;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSMutableString *message;

@end

@implementation PCTextingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self createAudioPlayer];
}

- (void)viewDidAppear: (BOOL) animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [self.audioPlayer play];
    [self.audioPlayer pause];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)createAudioPlayer {
    NSString *charactersFilepath = [[NSBundle mainBundle] pathForResource:@"characters" ofType:@"txt"];
    NSString *characters = [NSString stringWithContentsOfFile:charactersFilepath encoding:NSUTF8StringEncoding error:NULL];
    self.characterArray = [characters componentsSeparatedByString:@"|"];
    
    NSString *silenceFilepath = [[NSBundle mainBundle] pathForResource:@"silence" ofType:@"mp3"];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:silenceFilepath] error:NULL];
    self.audioPlayer.volume = 0.0;
    [self.audioPlayer setNumberOfLoops:-1];
    self.audioPlayer.delegate = self;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [self reset];
    
    [self.audioPlayer play];
    [self.audioPlayer pause];
}

- (void)reset {
    self.message = [[NSMutableString alloc] init];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:(@{MPMediaItemPropertyTitle : self.characterArray[0],
                                                               MPMediaItemPropertyAlbumTitle : @"To: Someone"})];
}

#pragma mark - Typing

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [self typeCurrentCharacter];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [self typeCurrentCharacter];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [self selectNextCharacter];
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self selectPreviousCharacter];
                break;
                
            default:
                break;
        }
        
    }
}

- (void)typeCurrentCharacter {
    NSString *character = self.characterArray[_characterIndex];
    
    if ([character isEqualToString:@"SEND"]) {
        //return [self sendMessage];
    }
    else if ([character isEqualToString:@"DELETE"]) {
        if ([self.message length] > 0) {
            [self.message deleteCharactersInRange:NSMakeRange(self.message.length - 1, 1)];
        }
        
    }
    else {
        [self.message appendString:character];
    }
        
    _fakeDiscNumber++;
    
    NSString *viewableMessage = self.message;
    
    if (viewableMessage.length >= PEBBLE_MAX_CHARACTER_COUNT) {
        viewableMessage = [viewableMessage substringFromIndex:viewableMessage.length - PEBBLE_MAX_CHARACTER_COUNT];
    }
    
    NSMutableDictionary *nowPlayingInfo = [[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] mutableCopy];
    nowPlayingInfo[MPMediaItemPropertyDiscNumber] = @(_fakeDiscNumber); // The Artist info is only refreshed when certain values of a song change, such as the disc number.
    nowPlayingInfo[MPMediaItemPropertyArtist] = viewableMessage;
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
    
    self.textView.text = self.message;
}

- (void)updateSelectedCharacter {
    NSMutableDictionary *nowPlayingInfo = [[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] mutableCopy];
    nowPlayingInfo[MPMediaItemPropertyTitle] = self.characterArray[_characterIndex];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
}

- (void)selectNextCharacter {    
    _characterIndex++;
    
    if (_characterIndex >= [self.characterArray count]) {
        _characterIndex = 0;
    }
    
    [self updateSelectedCharacter];
}

- (void)selectPreviousCharacter {    
    _characterIndex--;
    
    if (_characterIndex < 0) {
        _characterIndex = [self.characterArray count] - 1;
    }
    
    [self updateSelectedCharacter];
}

/*- (void)sendMessage:(NSString *)message isSMS:(BOOL)isSMS {
    if (isSMS) {
        CKSMSService *smsService = [CKSMSService sharedSMSService];
        
        //id ct = CTTelephonyCenterGetDefault();
        CKConversationList *conversationList = nil;
        //CKMadridService *madridService = [CKMadridService sharedMadridService];
        //NSString *foo = [madridService _temporaryFileURLforGUID:@"A5F70DCD-F145-4D02-B308-B7EA6C248BB2"];
        
        NSLog(@"Sending SMS");
        conversationList = [CKConversationList sharedConversationList];
        CKSMSEntity *ckEntity = [smsService copyEntityForAddressString:@"9722817016"];
        CKConversation *conversation = [conversationList conversationForRecipients:[NSArray arrayWithObject:ckEntity] create:YES service:smsService];
        NSString *groupID = [conversation groupID];
        CKSMSMessage *ckMsg = [smsService _newSMSMessageWithText:message forConversation:conversation];
        [smsService sendMessage:ckMsg];
    }
    else {
        CKMessageStandaloneComposition *composition = [CKMessageStandaloneComposition newCompositionForText:@"Test Message"];
        
        //Get a reference to the shared conversation list
        CKConversationList *conversationList = [CKConversationList sharedConversationList];
        
        //Get a reference to the shared Madrid Service
        CKMadridService *madridService = [CKMadridService sharedMadridService];
        
        NSString *messageRecipient = @"+1234567890"; // This is the phone number or email of the message recipient
        
        //Make a Conversation
        CKSubConversation *conversation = [conversationList conversationForGroupID:messageRecipient create:YES service:madridService];
        
        //Create a message
        CKMadridMessage *message = [madridService newMessageWithComposition:composition forConversation:conversation];
        
        [madridService sendMessage:message];
    }
}*/

/*- (void)sendMessage {
    __block MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
    messageComposeViewController.recipients = @[@"9722817016"];
    messageComposeViewController.body = self.message;
	messageComposeViewController.messageComposeDelegate = self;
    
	[messageComposeViewController viewWillAppear:NO];
	[messageComposeViewController view];
	[messageComposeViewController viewDidAppear:NO];
    
	UIViewController *topViewController = [messageComposeViewController topViewController];
	@try
	{
		// topViewController is a CKSMSComposeController : CKTranscriptController
		[topViewController viewWillAppear:NO];
		[topViewController view];
		[topViewController viewDidAppear:NO];
		id entryView = [topViewController valueForKey:@"entryView"];
		if ([entryView respondsToSelector:@selector(send:)])
			[entryView performSelector:@selector(send:) withObject:nil];
		else
			[self reset];
	}
	@catch (NSException *exception)
	{
        NSLog(@"%@", exception);
		[self reset];
	}
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
