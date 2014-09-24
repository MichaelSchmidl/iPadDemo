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

@synthesize dispS2 = _dispS2;

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


///////////////////////////////////////////////////////////////////////////////////////////////////
// functions we need to talk with the reader
///////////////////////////////////////////////////////////////////////////////////////////////////
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
}

- (void)turnReaderOFF{
    NSLog(@"turnReaderOFF");
    [TestFlight passCheckpoint:@"turnReaderOFF"];
    
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
            NSLog(@"%@", [NSString stringWithFormat:@"n=%lu <%@>", [data length], data]);
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
                NSLog(@"i=%lu", i);
            }
            
            if ((i > 0))// && (KBD_unknown != kbdStatus)) // if the last character was not CR or LF, show the current string
            {
//                NSString* newStr = [NSString stringWithUTF8String:readBytes];
//                [_dispRFID setText:newStr];
//                [_dispRFID setTextColor:[UIColor blackColor]];
            }
            else // if the last character was CR or LF so the string index is ZERO, zero the string as well
            {
                readBytes[i] = 0;
            }
#if 0
            // see whether we got "k0" or "k1" so we know the KBD status now
            if ((KBD_unknown == kbdStatus) && (2 == i)){
                if ('k' == readBytes[0]){
                    switch (readBytes[1]){
                        case '0':
                            NSLog(@"got k0");
                            [_KBDButton setTitle:@"OFF" forState:UIControlStateNormal];
                            [_KBDButton setEnabled:TRUE];
                            kbdStatus = KBD_off;
                            i = 0; // discard the KBD status message
                            break;
                        case '1':
                            NSLog(@"got k1");
                            [_KBDButton setTitle:@"ON" forState:UIControlStateNormal];
                            [_KBDButton setEnabled:TRUE];
                            [_dispRFID becomeFirstResponder];
                            kbdStatus = KBD_on;
                            i = 0; // discard the KBD status message
                            break;
                        default:
                            break;
                    }
                }
            }
#endif
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
//    kbdStatus = KBD_unknown;
//    [_KBDButton setEnabled:FALSE];
//    [_KBDButton setTitle:@"???" forState:UIControlStateNormal];
//    [_dispRFID resignFirstResponder];
}

@end
