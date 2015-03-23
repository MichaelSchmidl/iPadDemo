//
//  ViewController.h
//  iPadDemo
//
//  Created by Michael Schmidl on 23.09.14.
//  Copyright (c) 2014 Michael Schmidl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import "Header.h"


@interface ViewController : UIViewController
{
    NSMutableArray *_accessoryList;
    EAAccessory *_accessory;
    EAAccessory *_selectedAccessory;
    
    IBOutlet UIButton *OnOffButton;
    IBOutlet UIButton *KbdButton;
    IBOutlet UIButton *GIButton;
}

@property (nonatomic, retain) IBOutlet UITextField *dispS1;
@property (nonatomic, retain) IBOutlet UILabel *dispS2;
@property (nonatomic, retain) IBOutlet UILabel *dispS3;
@property (nonatomic, retain) IBOutlet UITextField *dispS4;

-(IBAction) OnOffAction:(id)sender;
-(IBAction) KbdAction:(id)sender;
-(IBAction) GIAction:(id)sender;
-(IBAction) HIDAction:(id)sender;

@end
