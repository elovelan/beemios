//
//  SettingsViewController.h
//  Beeminder
//
//  Created by Andy Brett on 6/18/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BeeminderViewController.h"

@interface SettingsViewController : UIViewController

- (IBAction)signOutButtonPressed;
@property (strong, nonatomic) IBOutlet UILabel *loggedInAsLabel;

@end
