//
//  ViewController.h
//  iPadDemo
//
//  Created by Michael Schmidl on 23.09.14.
//  Copyright (c) 2014 Michael Schmidl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ExternalAccessory/ExternalAccessory.h>


@interface ViewController : UIViewController
{
    NSMutableArray *_accessoryList;
    EAAccessory *_accessory;
    EAAccessory *_selectedAccessory;
}


@end

