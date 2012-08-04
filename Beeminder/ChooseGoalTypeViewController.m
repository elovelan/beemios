//
//  ChooseGoalTypeViewController.m
//  Beeminder
//
//  Created by Andy Brett on 7/30/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import "ChooseGoalTypeViewController.h"

@interface ChooseGoalTypeViewController ()

@end

@implementation ChooseGoalTypeViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary *fatLoser = [NSDictionary dictionaryWithObjectsAndKeys:kFatloserPublic, @"publicName", kFatloserPrivate, @"privateName", nil];
    
    NSDictionary *hustler = [NSDictionary dictionaryWithObjectsAndKeys:kHustlerPublic, @"publicName", kHustlerPrivate, @"privateName", nil];
    
    NSDictionary *biker = [NSDictionary dictionaryWithObjectsAndKeys:kBikerPublic, @"publicName", kBikerPrivate, @"privateName", nil];
    
    self.goalTypes = [NSArray arrayWithObjects:fatLoser, hustler, biker, nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.goalTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Goal Type Cell"];
    

    cell.textLabel.text = [[self.goalTypes objectAtIndex:indexPath.row] objectForKey:@"publicName"];
    
    if ([self.goalObject.gtype isEqualToString:[[self.goalTypes objectAtIndex:indexPath.row] objectForKey:@"privateName"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.goalObject.gtype = [[self.goalTypes objectAtIndex:indexPath.row] objectForKey:@"privateName"];
    
    [[NSManagedObjectContext MR_defaultContext] MR_save];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        [self.presentingViewController dismissModalViewControllerAnimated:YES];
    });
    

}

@end
