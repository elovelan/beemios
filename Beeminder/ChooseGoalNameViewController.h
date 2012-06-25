//
//  ChooseGoalNameViewController.h
//  Beeminder
//
//  Created by Andy Brett on 6/22/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChooseGoalNameViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *goalNameTextField;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UITextField *activeField;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSArray *goalSlugs;
@property (strong, nonatomic) IBOutlet UILabel *goalSlugExitsWarningLabel;

@end
