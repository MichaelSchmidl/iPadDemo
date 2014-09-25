//
//  ViewController.m
//  iPadDemo
//
//  Created by Michael Schmidl on 23.09.14.
//  Copyright (c) 2014 Michael Schmidl. All rights reserved.
//

#import "ViewController.h"
#import "EADSessionController.h"
#import "TestFlight.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize dispS1 = _dispS1;
@synthesize dispS2 = _dispS2;
@synthesize dispS3 = _dispS3;
@synthesize dispS4 = _dispS4;

// used to communicate with the RFID reader
EADSessionController *sessionController;

// keep track of the current reader status
typedef enum
{
    open_READER,
    no_READER,
    active_READER,
    disabled_READER
}eReaderStatus;
eReaderStatus readerStatus = no_READER;

// keep track of the current HID status
typedef enum
{
    KBD_unknown,
    KBD_on,
    KBD_off
}eKbdStatus;
eKbdStatus kbdStatus = KBD_unknown;

// local buffer to collect the data comming in from the accessory
#define MAX_READ_LENGTH 500
uint8_t readString[MAX_READ_LENGTH];

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // regigister notifications so we know the accessory connects, disconnects or sent data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    // first action after start of the application is to check wether a reader is connected
    [self searchForReader];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// actions
///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    NSLog(@"textFieldShouldReturn");
    return YES;
}

-(void) HIDAction:(id)sender{
    NSLog(@"HIDAction");
}

-(void) OnOffAction:(id)sender{
    NSLog(@"OnOffAction");
    switch(readerStatus)
    {
        case disabled_READER:
            [self turnReaderON];
            break;
        case active_READER:
            [self turnReaderOFF];
            break;
        case no_READER:
        default:
            [self searchForReader];
            [_dispS2 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"NoReader_preference"]];
            [_dispS2 setTextColor:[UIColor redColor]];
            break;
    } // switch readerStatus
}

-(void) KbdAction:(id)sender{
    NSLog(@"KbdAction");
    switch(kbdStatus)
    {
        case KBD_off:
            [self turnHIDON];
            break;
        case KBD_unknown:
        case KBD_on:
        default:
            [self turnHIDOFF];
            break;
    } // switch readerStatus
}


-(void) GIAction:(id)sender{
    NSLog(@"GIAction");

    // change the icon to indicate we wait for an ID
    [GIButton setImage:[UIImage imageNamed:@"GetBadgeID-OFF.png"] forState:UIControlStateNormal];

    // send the GI string to the READER
    char cStr[100];
    NSInteger EOLchar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"] integerValue];
    if (NULL != [[NSUserDefaults standardUserDefaults] stringForKey:@"GI_command_preference"])
    {
        sprintf(cStr, "%s%c", [[[NSUserDefaults standardUserDefaults] stringForKey:@"GI_command_preference"] UTF8String], (char)EOLchar);
    }
    else
    {
        sprintf(cStr, "GI\n");
    }
    int len = (int)strlen(cStr);
    [[EADSessionController sharedController] writeData:[NSData dataWithBytes:cStr length:len]];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// functions we need to talk with the reader
///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)turnHIDON{
    NSLog(@"turnHIDON");
    [TestFlight passCheckpoint:@"turnHIDON"];
    
    // send the HIDON string to the READER
    char cStr[100];
    NSInteger EOLchar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"] integerValue];
    if (NULL != [[NSUserDefaults standardUserDefaults] stringForKey:@"HIDON_command_preference"])
    {
        sprintf(cStr, "%s%c", [[[NSUserDefaults standardUserDefaults] stringForKey:@"HIDON_command_preference"] UTF8String], (char)EOLchar);
    }
    else
    {
        sprintf(cStr, "k1\n");
    }
    int len = (int)strlen(cStr);
    [[EADSessionController sharedController] writeData:[NSData dataWithBytes:cStr length:len]];
    
    // show the status as text in the S3
    [_dispS3 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"HID_ON_preference"]];
    kbdStatus = KBD_on;

    [_dispS4 becomeFirstResponder];
    [_dispS4 setText:@""];

}

- (void)turnHIDOFF{
    NSLog(@"turnHIDOFF");
    [TestFlight passCheckpoint:@"turnHIDOFF"];
    
    // send the HIDOFF command to the reader
    char cStr[100];
    NSInteger EOLchar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"] integerValue];
    if (NULL != [[NSUserDefaults standardUserDefaults] stringForKey:@"HIDOFF_command_preference"])
    {
        sprintf(cStr, "%s%c", [[[NSUserDefaults standardUserDefaults] stringForKey:@"HIDOFF_command_preference"] UTF8String], (char)EOLchar);
    }
    else
    {
        sprintf(cStr, "k0\n");
    }
    int len = (int)strlen(cStr);
    [[EADSessionController sharedController] writeData:[NSData dataWithBytes:cStr length:len]];
    
    // show the status as text in S3
    [_dispS3 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"HID_OFF_preference"]];
    kbdStatus = KBD_off;

    [_dispS4 resignFirstResponder];
}

- (void)turnReaderON{
    NSLog(@"turnReaderON");
    [TestFlight passCheckpoint:@"turnReaderON"];
    
    // send the ON string to the READER
    char cStr[100];
    NSInteger EOLchar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"] integerValue];
    if (NULL != [[NSUserDefaults standardUserDefaults] stringForKey:@"ON_command_preference"])
    {
        sprintf(cStr, "%s%c", [[[NSUserDefaults standardUserDefaults] stringForKey:@"ON_command_preference"] UTF8String], (char)EOLchar);
    }
    else
    {
        sprintf(cStr, "ON\n");
    }
    int len = (int)strlen(cStr);
    [[EADSessionController sharedController] writeData:[NSData dataWithBytes:cStr length:len]];
    
    // change the button icon
    [OnOffButton setImage:[UIImage imageNamed:@"ReaderPower-ON.png"] forState:UIControlStateNormal];
    readerStatus = active_READER;
    
    // show the status also as text in the S2
    [_dispS2 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"ReaderPower_ON_preference"]];
    [_dispS2 setTextColor:[UIColor lightGrayColor]];
    
    // enable the other two buttons
    [KbdButton setEnabled:TRUE];
    [GIButton setEnabled:TRUE];
    // and show the S3 status
    [_dispS3 setHidden:FALSE];
    [self turnHIDOFF];
}

- (void)turnReaderOFF{
    NSLog(@"turnReaderOFF");
    [TestFlight passCheckpoint:@"turnReaderOFF"];
    
    [self turnHIDOFF];
    
    // send the OFF command to the reader
    char cStr[100];
    NSInteger EOLchar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"] integerValue];
    if (NULL != [[NSUserDefaults standardUserDefaults] stringForKey:@"OFF_command_preference"])
    {
        sprintf(cStr, "%s%c", [[[NSUserDefaults standardUserDefaults] stringForKey:@"OFF_command_preference"] UTF8String], (char)EOLchar);
    }
    else
    {
        sprintf(cStr, "OFF\n");
    }
    int len = (int)strlen(cStr);
    [[EADSessionController sharedController] writeData:[NSData dataWithBytes:cStr length:len]];
    
    // change the button icon
    [OnOffButton setImage:[UIImage imageNamed:@"ReaderPower-Off.png"] forState:UIControlStateNormal];
    readerStatus = disabled_READER;
    
    // show the status also as text in S2
    [_dispS2 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"ReaderPower_OFF_preference"]];
    [_dispS2 setTextColor:[UIColor lightGrayColor]];
    
    // disable the other two buttons
    [KbdButton setEnabled:FALSE];
    [GIButton setEnabled:FALSE];
    
    // and hide the S3 status
    [_dispS3 setHidden:TRUE];
}

- (void)searchForReader{
    [TestFlight passCheckpoint:@"searchForReader"];
    
    sessionController = [EADSessionController sharedController];
    _accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
    //TODO: what happens if other accessories are connected, too?
    if ([_accessoryList count] > 0)
    {
        _selectedAccessory = [_accessoryList objectAtIndex:0];
        NSLog(@"open reader communication");
        [sessionController setupControllerForAccessory:_selectedAccessory withProtocolString:@"com.rfideas.reader"];
        if (TRUE == [sessionController openSession])
        {
            [self turnReaderOFF];
        }
        else
        {
            NSLog(@"failed to openSession");
            readerStatus = no_READER;
            [_dispS2 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"NoReader_preference"]];
            [_dispS2 setTextColor:[UIColor redColor]];
        }
    }
    else
    {
        NSLog(@"no reader found");
        readerStatus = no_READER;
        [_dispS2 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"NoReader_preference"]];
        [_dispS2 setTextColor:[UIColor redColor]];
        [_dispS3 setHidden:TRUE];
    }
}



///////////////////////////////////////////////////////////////////////////////////////////////////
// now we implement methods to handle the three accessory notifications
///////////////////////////////////////////////////////////////////////////////////////////////////
// Data was received from the accessory
- (void)_sessionDataReceived:(NSNotification *)notification
{
#define MAX_READBYTES 500
    static char readBytes[MAX_READBYTES+1] = "";
    
    NSInteger EOLchar = [[[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"] integerValue];
    if (0 == EOLchar) EOLchar = 13;
    
    EADSessionController *sessionController = (EADSessionController *)[notification object];
    NSInteger bytesAvailable = 0;
    
    //TODO: do this with Objective-C
    while ((bytesAvailable = [sessionController readBytesAvailable]) > 0) {
        NSData *data = [sessionController readData:bytesAvailable];
        if (data) {
            //NSLog(@"%@", [NSString stringWithFormat:@"n=%lu <%@>", (unsigned long)[data length], data]);
            NSInteger n = [data length];
            NSInteger i = strlen(readBytes);
            const char *bytes = [data bytes];
            while (n--)
            {
                if ((char)EOLchar == *bytes)
                {
                    i=0;
                    bytes++;
                }
                else
                {
                    readBytes[i++] = *bytes++;
                    readBytes[i] = 0;
                    if (MAX_READBYTES <= i) i = MAX_READBYTES-1;
                }
                //NSLog(@"i=%lu", (long)i);
            }
            
            if ((i > 0))// && (KBD_unknown != kbdStatus)) // if the last character was not CR or LF, show the current string
            {
                NSString* newStr = [NSString stringWithUTF8String:readBytes];
                [_dispS1 setText:newStr];
            }
            else // if the last character was CR or LF so the string index is ZERO, zero the string as well
            {
                readBytes[i] = 0;
                // change the icon to indicate we got an ID
                [GIButton setImage:[UIImage imageNamed:@"GetBadgeID-ON.png"] forState:UIControlStateNormal];
            }
        }
    }
}

// accessory got connected
- (void)_accessoryDidConnect:(NSNotification *)notification {
    NSLog(@"accessoryDidConnect");
    [TestFlight passCheckpoint:@"accessoryDidConnect"];
    readerStatus = open_READER;
    [self searchForReader];
}

// accessory disappeared
- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    NSLog(@"accessoryGotLost");
    [TestFlight passCheckpoint:@"accessoryGotLost"];
    [OnOffButton setImage:[UIImage imageNamed:@"ReaderPower-Off.png"] forState:UIControlStateNormal];
    readerStatus = no_READER;
    [_dispS2 setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"NoReader_preference"]];
    [_dispS2 setTextColor:[UIColor redColor]];
    [_dispS3 setHidden:TRUE];
    [_dispS4 resignFirstResponder];
}

@end
