//
//  GameKitCommunicatorViewController.h
//  CS247_iPad
//
//  Created by Elliot Babchick on 2/9/11.
//  Copyright 2011 Stanford University. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface GameKitCommunicatorViewController : UIViewController<GKPeerPickerControllerDelegate,GKSessionDelegate> {
	GKPeerPickerController *mPicker;
	GKSession *mSession;
	IBOutlet UITextField *mTextField;
	IBOutlet UITextView *mTextView;
	IBOutlet UIImageView *imgView;
	IBOutlet UIActivityIndicatorView *spinner;
	NSMutableArray *mPeers;
	NSUInteger chunks;
	NSUInteger totalChunks;
	NSMutableData *data;
}

-(IBAction) connectClicked:(id)sender;
-(IBAction) sendData:(id)sender;
@property (retain) GKSession *mSession;
@property (retain) NSMutableData *data;
@property NSUInteger chunks;
@property NSUInteger totalChunks;
@property (retain) UIActivityIndicatorView *spinner;


@end