//
//  GameKitCommunicatorViewController.m
//  CS247_iPhone
//
//  Created by Elliot Babchick on 2/9/11.
//  Copyright 2011 Stanford University. All rights reserved.
//

#import "GameKitCommunicatorViewController.h"
#import	<CoreGraphics/CoreGraphics.h>

@implementation GameKitCommunicatorViewController

@synthesize mSession, imageToSend;


/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	mPicker=[[GKPeerPickerController alloc] init];
	mPicker.delegate=self;
	mPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
	mPeers=[[NSMutableArray alloc] init];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[mPeers release];
    [super dealloc];
}

#pragma mark Events

-(IBAction) connectClicked:(id)sender{
	//Show the connector
	[mPicker show];
}

- (IBAction)takeImageClicked:(id)sender {
	[self presentModalViewController:self.imagePicker animated:YES];
}

#pragma mark PeerPickerControllerDelegate stuff

/* Notifies delegate that a connection type was chosen by the user.
 */
- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type{
	if (type == GKPeerPickerConnectionTypeOnline) {
        picker.delegate = nil;
        [picker dismiss];
        [picker autorelease];
		// Implement your own internet user interface here.
    }
}

/* Notifies delegate that the connection type is requesting a GKSession object.
 
 You should return a valid GKSession object for use by the picker. If this method is not implemented or returns 'nil', a default GKSession is created on the delegate's behalf.
 */
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type{
	
	//UIApplication *app=[UIApplication sharedApplication];
	
	GKSession* session = [[GKSession alloc] initWithSessionID:@"iPad" displayName:@"FaceStory iPhone" sessionMode:GKSessionModePeer];
   // [session autorelease];
    return session;
}

/* Notifies delegate that the peer was connected to a GKSession.
 */
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session{
	
	NSLog(@"Connected from %@",peerID);
	picView.alpha = 0;
	picView.hidden = NO;
	[UIView animateWithDuration:1 animations:^{ picView.alpha = 1; connectButton.alpha= 0;} completion:^(BOOL finished) { 	connectButton.hidden = YES; }];
	 // Use a retaining property to take ownership of the session.
    self.mSession = session;
	// Assumes our object will also become the session's delegate.
    session.delegate = self;
    [session setDataReceiveHandler: self withContext:nil];
	// Remove the picker.
    picker.delegate = nil;
    [picker dismiss];
    [picker autorelease];
	// Start your game.
}

-(IBAction) sendData:(id)sender{

	//Encode image
	if (imageToSend == NULL) {
		imageToSend = [UIImage imageNamed:@"stealmic.png"];
	}
	NSData *imageData = UIImageJPEGRepresentation(imageToSend,.1);
	
	//Send how many chunks over
	NSUInteger fiftyK = 51200;
	NSUInteger chunkCount = (((NSUInteger)(imageData.length / fiftyK)) + (((imageData.length % fiftyK) == 0 ) ? 0 : 1));
	NSString *chunkCountStr = [NSString stringWithFormat:@"%d",chunkCount];
	NSLog(@"I'm %@", chunkCountStr);
	NSData* chunkCountData = [chunkCountStr dataUsingEncoding: NSASCIIStringEncoding];
	[mSession sendData:chunkCountData toPeers:mPeers withDataMode:GKSendDataReliable error:nil];
	
	// Send chunks
	NSData *dataToSend;
	NSRange range = {0, 0};
	for(NSUInteger i=0;i<imageData.length;i+=fiftyK){
		if (i + fiftyK <= imageData.length) {
		range = NSMakeRange(i, fiftyK);
		dataToSend = [imageData subdataWithRange:range];
		[mSession sendData:dataToSend toPeers:mPeers withDataMode:GKSendDataReliable error:nil];
		}
	}
	NSUInteger remainder = (imageData.length % fiftyK);
	if (remainder != 0){
		range = NSMakeRange(imageData.length - remainder, remainder);
		dataToSend = [imageData subdataWithRange:range];
		[mSession sendData:dataToSend toPeers:mPeers withDataMode:GKSendDataReliable error:nil];
	}
	    
	NSLog(@"GOT OUT");
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    // Read the bytes in data and perform an application-specific action.
	
	NSLog(@"Received Data from %@",peer);
	
	
}

/* Notifies delegate that the user cancelled the picker.
 */
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker{
	
}

#pragma mark editing image
//
//+ (UIImage *)applyEllipseToImage:(UIImage *)originalImage {
//	CGImageRef originalImageCG = originalImage.CGImage;
//	
//	
//	
//}

- (UIImage *)clipImage:(UIImage *)imageIn withMask:(UIImage *)maskIn atRect:(CGRect) maskRect
{
    CGRect rect = CGRectMake(0, 0, imageIn.size.width, imageIn.size.height);
    CGImageRef msk = maskIn.CGImage;
	
    UIGraphicsBeginImageContext(imageIn.size);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // Clear whole thing
    CGContextClearRect(ctx, rect);
	
    // Create the masked clipping region
    CGContextClipToMask(ctx, maskRect, msk);
	
    CGContextTranslateCTM(ctx, 0.0, rect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
	
    // Draw view into context
    CGContextDrawImage(ctx, rect, imageIn.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
	
    return newImage;
}

//- (unsigned char *)bitmapFromImage:(UIImage *)image {
//	
//    //Create a bitmap for the given image.
//    CGContextRef contex = CreateARGBBitmapContext(image.size);
//    if (contex == NULL) {
//        return NULL;
//    }
//	
//    CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
//    CGContextDrawImage(contex, rect, image.CGImage);
//    unsigned char *data = CGBitmapContextGetData(contex);
//    CGContextRelease(contex);
//    return data;
//}

#pragma mark ImagePicker stuff

- (UIImageView *)backgroundImageView
{
	if ([self.view.subviews count] && [[self.view.subviews objectAtIndex:0] isKindOfClass:[UIImageView class]]) {
		return (UIImageView *)[self.view.subviews objectAtIndex:0];
	} else {
		return nil;
	}
}


- (void)setBackgroundImage:(UIImage *)image
{
	UIImageView *backgroundImageView = self.backgroundImageView;
	if (!backgroundImageView) {
		backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
		[self.view insertSubview:backgroundImageView atIndex:0];
		[backgroundImageView release];
	}
	backgroundImageView.image = image;
}		

- (UIImage *)backgroundImage
{
	return self.backgroundImageView.image;
}


- (UIImagePickerController *)imagePicker {
	if (!imagePicker) {
		imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.delegate = self;
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
		} // defaults to photo library
		CFStringRef desired = kUTTypeImage;
		if ([[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType] containsObject:desired]) {
			imagePicker.mediaTypes = [NSArray arrayWithObject:desired];
		}
		imagePicker.allowsEditing = NO;
	}
	return imagePicker;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	if (image) {
		imageToSend = image;
	}
	[self sendData:self];
	[self dismissModalViewControllerAnimated:YES];
    picView.hidden = NO;
	connectButton.hidden = YES;
}


#pragma mark GameSessionDelegate stuff

/* Indicates a state change for the given peer.
 */
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	NSLog(@"STATE CHANGED");
	switch (state)
    {
        case GKPeerStateConnected:
		{
			NSLog(@"Connected");
			[mPeers addObject:peerID];
			break;
		}
        case GKPeerStateDisconnected:
		{
			[mPeers removeObject:peerID];
			picView.hidden = YES;
			connectButton.hidden = NO;
			NSLog(@"Disconnected");
			break;
		}
    }
}

@end