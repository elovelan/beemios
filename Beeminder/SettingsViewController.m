//
//  SettingsViewController.m
//  Beeminder
//
//  Created by Andy Brett on 6/18/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController
@synthesize loggedInAsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.loggedInAsLabel.text = [NSString stringWithFormat:@"Logged in as: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"username"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)signOutButtonPressed {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"authenticationTokenKey"];
    [defaults setObject:nil forKey:@"username"];
    
    UINavigationController *navCon = [self navigationController];
    
    while (![navCon isKindOfClass:[BeeminderViewController class]]) {
        navCon = [navCon navigationController];
    }
    
    [navCon popToRootViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    [self setLoggedInAsLabel:nil];
    [super viewDidUnload];
}
@end
