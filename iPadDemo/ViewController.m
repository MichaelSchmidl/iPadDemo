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

// used to communicate with the RFID reader
EADSessionController *sessionController;

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
// functions we need to talk with the reader
///////////////////////////////////////////////////////////////////////////////////////////////////
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
            // at first request the current KBD status
            [[EADSessionController sharedController] writeData:(NSData*)[@"k?" dataUsingEncoding:NSUTF8StringEncoding]];
            //        [self turnReaderOFF];
        }
        else
        {
            NSLog(@"failed to openSession");
        }
    }
    else
    {
        NSLog(@"no reader found");
//        [_dispRFID setText:@"-- no reader found --"];
//        [_dispRFID setTextColor:[UIColor redColor]];
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
//    readerStatus = open_READER;
    [self searchForReader];
}

// accessory disappeared
- (void)_accessoryDidDisconnect:(NSNotification *)notification {
    NSLog(@"accessoryGotLost");
    [TestFlight passCheckpoint:@"accessoryGotLost"];
//    [OnOffButton setImage:[UIImage imageNamed:@"Button-Info-icon.png"] forState:UIControlStateNormal];
//    readerStatus = no_READER;
//    [_dispRFID setText:@"no reader connected"];
//    [_dispRFID setTextColor:[UIColor redColor]];
//    kbdStatus = KBD_unknown;
//    [_KBDButton setEnabled:FALSE];
//    [_KBDButton setTitle:@"???" forState:UIControlStateNormal];
//    [_dispRFID resignFirstResponder];
}

@end
