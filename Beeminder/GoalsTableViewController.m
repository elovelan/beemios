//
//  GoalsTableViewController.m
//  Beeminder
//
//  Created by Andy Brett on 6/18/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import "GoalsTableViewController.h"
#import "AFJSONRequestOperation.h"


@interface GoalsTableViewController ()

@end

@implementation GoalsTableViewController
@synthesize refreshButton;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBarController.tabBar.backgroundImage = [[UIImage alloc] init];
    self.tabBarController.tabBar.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0f];
    self.tabBarController.tabBar.selectionIndicatorImage = [[UIImage alloc] init];
    self.tabBarController.tabBar.selectedImageTintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0f];
    
    self.hasCompletedDataFetch = NO;
    
    [BeeminderAppDelegate requestPushNotificationAccess];

    self.pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.tableView];
    [self.pull setDelegate:self];
    [self.tableView addSubview:self.pull];
    
    self.tableView.rowHeight = 92.0f;
    self.tableView.backgroundColor = [BeeminderAppDelegate cloudsColor];
    self.goalComparator = ^(id a, id b) {
        double aBackburnerPenalty = [[a burner] isEqualToString:@"backburner"] ? 1000000000000 : 0;
        double bBackburnerPenalty = [[b burner] isEqualToString:@"backburner"] ? 1000000000000 : 0;
        if ([[a panicTime] doubleValue] + aBackburnerPenalty - ([[b panicTime] doubleValue] + bBackburnerPenalty) > 0) {
            return 1;
        }
        else {
            return -1;
        }
    };
    [self.tableView setSectionFooterHeight:[self.tableView cellForRowAtIndexPath:[[NSIndexPath alloc] initWithIndex:0]].frame.size.height];
    
    User *user = [ABCurrentUser user];

    NSArray *arrayOfGoalObjects = [[user.goals allObjects] sortedArrayUsingComparator:self.goalComparator];
    self.goalObjects = [NSMutableArray arrayWithArray:arrayOfGoalObjects];
    
    self.frontburnerGoalObjects = [NSMutableArray arrayWithArray:[[user.goals allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Goal *g = (Goal *)evaluatedObject;
        return [g.burner isEqualToString:@"frontburner"];
    }]]];
    
    self.backburnerGoalObjects = [NSMutableArray arrayWithArray:[[user.goals allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Goal *g = (Goal *)evaluatedObject;
        return [g.burner isEqualToString:@"backburner"];
    }]]];
    
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flat-refresh"]];
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fetchEverything)];
    [view addGestureRecognizer:recognizer];
    self.refreshButton = [[UIBarButtonItem alloc] initWithCustomView:view];
    self.refreshButton.target = self;
    self.refreshButton.action = @selector(fetchEverything);
    self.navigationItem.rightBarButtonItem = self.refreshButton;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kGoToGoalWithSlugKey]) {
        [self goToGoalWithSlug:[[NSUserDefaults standardUserDefaults] objectForKey:kGoToGoalWithSlugKey]];
    }

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(25,0, 227, 32)];
    self.titleLabel.text = @"Your Goals";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.font = [UIFont fontWithName:@"Lato-Bold" size:20.0f];
    self.titleLabel.textAlignment = UITextAlignmentCenter;
    self.navigationItem.titleView = self.titleLabel;
    
    [self fetchEverything];
}

- (void)goToGoalWithSlug:(NSString *)slug
{
    NSIndexSet *set = [self.goalObjects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Goal *goal = (Goal *)obj;
        return [goal.slug isEqualToString:slug];
    }];
    
    [set lastIndex];
    
    NSIndexPath *path = [NSIndexPath indexPathForItem:[set lastIndex] inSection:0];
    
    [self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    [self performSegueWithIdentifier:@"segueToGoalSummaryView" sender:self];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
    [self performSelectorInBackground:@selector(fetchEverything) withObject:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (![ABCurrentUser accessToken]) {
        [self failedFetch];
        return;
    }
}

- (IBAction)refreshPressed:(UIBarButtonItem *)sender
{
    [self fetchEverything];
}

- (void)fetchEverything
{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.activityIndicator startAnimating];    
    self.refreshButton = [[self.navigationItem rightBarButtonItem] initWithCustomView:self.activityIndicator];
    
    if (![ABCurrentUser accessToken]) {
        [self failedFetch];
        return;
    }
    
    NSString *username = [ABCurrentUser username];
    int lastUpdatedAt = [ABCurrentUser lastUpdatedAt];

    NSURL *fetchUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/users/%@.json?associations=true&datapoints_count=3&diff_since=%d&access_token=%@", kBaseURL, kAPIPrefix, username, lastUpdatedAt, [ABCurrentUser accessToken]]];
    
    NSURLRequest *fetchRequest = [NSURLRequest requestWithURL:fetchUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:300];
    
    [ABCurrentUser setLastUpdatedAtToNow];
    MBProgressHUD *hud;
    BOOL initialImport = (!lastUpdatedAt || lastUpdatedAt == 0);
    if (initialImport) {
        User *user = [ABCurrentUser user];
        for (Goal *goal in user.goals) {
            [[NSManagedObjectContext MR_defaultContext] deleteObject:goal];
        }
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Fetching Beeswax...";
        hud.labelFont = [UIFont fontWithName:@"Lato" size:14.0f];
    }

    [[AFJSONRequestOperation JSONRequestOperationWithRequest:fetchRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (initialImport) {
            hud.mode = MBProgressHUDModeDeterminate;
            hud.progress = 0.0f;
            hud.labelText = @"Importing Beeswax...";
            hud.labelFont = [UIFont fontWithName:@"Lato" size:14.0f];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self successfulFetchEverythingJSON:JSON progressCallback:^(float incrementBy){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (initialImport) [hud setProgress:hud.progress + incrementBy];
                    [self.tableView reloadData];
                });
            }];
            for (Goal *goal in self.goalObjects) {
                [goal updateGraphImageThumb];
            }
        });

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [self failedFetch];
    }] start];
}

- (void)viewDidUnload
{
    [self setRefreshButton:nil];
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.frontburnerGoalObjects.count;
    }
    return self.backburnerGoalObjects.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 10)];
        view.backgroundColor = [BeeminderAppDelegate silverColor];
        return view;
    }
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 10;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 1 &&
        indexPath.row >= self.backburnerGoalObjects.count) {
//        cell.textLabel.font = [UIFont fontWithName:@"Lato-Bold" size:18.0f];
//        cell.textLabel.text = @"Add New Goal";
//        cell.detailTextLabel.text = @"";
    }
    else {
        if (self.goalObjects.count > 0) {
            Goal *goal;
            if (indexPath.section == 0) {
                goal = [self.goalObjects objectAtIndex:indexPath.row];
            }
            else {
                goal = [self.goalObjects objectAtIndex:indexPath.row + self.frontburnerGoalObjects.count];
            }
            cell.textLabel.text = goal.title;
            cell.textLabel.font = [UIFont fontWithName:@"Lato-Bold" size:18.0f];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.minimumFontSize = 14.0f;
            cell.detailTextLabel.text = [goal losedateTextBrief:YES];
            cell.detailTextLabel.textColor = goal.losedateColor;
            cell.detailTextLabel.font = [UIFont fontWithName:@"Lato-Bold" size:15.0f];
            cell.indentationLevel = 3.0;
            cell.indentationWidth = 40.0;
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 10, 106, 70)];
            if (goal.graph_image_thumb) {
                imageView.image = goal.graph_image_thumb;
            }
            else {
                [MBProgressHUD showHUDAddedTo:imageView animated:YES];
                [self pollUntilThumbnailURLIsPresentForGoal:goal withTimer:nil];
            }

            [cell addSubview:imageView];
            cell.backgroundColor = [BeeminderAppDelegate silverColor];
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 &&
        indexPath.row >= self.backburnerGoalObjects.count) {
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//        UINavigationController *newGoalNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"newGoalNavigationController"];
//        [self presentViewController:newGoalNavigationController animated:YES completion:nil];
    }
    else {
        [self performSegueWithIdentifier:@"segueToGoalSummaryView" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToAddGoal"]) {
        // do nothing
    }
    else {
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        Goal *goalObject;
        if (path.section == 0) {
            goalObject = [self.goalObjects objectAtIndex:path.row];
        }
        else {
            goalObject = [self.goalObjects objectAtIndex:path.row + self.frontburnerGoalObjects.count];
        }

        [segue.destinationViewController setTitle:goalObject.title];
        [segue.destinationViewController setGoalObject:goalObject];
        [segue.destinationViewController setNeedsFreshData:!self.hasCompletedDataFetch || [[NSUserDefaults standardUserDefaults] objectForKey:kGoToGoalWithSlugKey]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGoToGoalWithSlugKey];
    }
}

- (void)successfulFetchEverythingJSON:(NSDictionary *)responseJSON progressCallback:(void(^)(float incrementBy))progressCallback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self replaceRefreshButton];
        [self.pull finishedLoading];
    });
    
    NSArray *deletedGoals = [responseJSON objectForKey:@"deleted_goals"];
    
    for (NSDictionary *goalDict in deletedGoals) {
        Goal *goal = [Goal MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"serverId = %@", [goalDict objectForKey:@"id"]] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (goal) [[NSManagedObjectContext MR_defaultContext] deleteObject:goal];
    }
    
    NSArray *goals = [responseJSON objectForKey:@"goals"];
    
    [self.goalObjects removeAllObjects];
    [self.frontburnerGoalObjects removeAllObjects];
    [self.backburnerGoalObjects removeAllObjects];
    
    for (NSDictionary *goalDict in goals) {
        progressCallback(1.0f/[goals count]);
        
        NSDictionary *modGoalDict = [Goal processGoalDictFromServer:goalDict];
        
        Goal *goal = [Goal writeToGoalWithDictionary:modGoalDict forUserWithUsername:[ABCurrentUser username]];
        [self.goalObjects addObject:goal];
    }
    User *user = [ABCurrentUser user];
    [self.goalObjects removeAllObjects];
    [self.frontburnerGoalObjects removeAllObjects];
    [self.backburnerGoalObjects removeAllObjects];
    
    NSArray *arrayOfGoalObjects = [[user.goals allObjects] sortedArrayUsingComparator:self.goalComparator];
    self.goalObjects = [NSMutableArray arrayWithArray:arrayOfGoalObjects];
    
    self.frontburnerGoalObjects = [NSMutableArray arrayWithArray:[[user.goals allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Goal *g = (Goal *)evaluatedObject;
        return [g.burner isEqualToString:@"frontburner"];
    }]]];
    
    self.backburnerGoalObjects = [NSMutableArray arrayWithArray:[[user.goals allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Goal *g = (Goal *)evaluatedObject;
        return [g.burner isEqualToString:@"backburner"];
    }]]];
    
    [BeeminderAppDelegate updateApplicationIconBadgeCount];
    self.hasCompletedDataFetch = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kGoToGoalWithSlugKey]) {
            [self goToGoalWithSlug:[[NSUserDefaults standardUserDefaults] objectForKey:kGoToGoalWithSlugKey]];
        }
        [self.tableView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}

- (void)replaceRefreshButton
{
    [self.activityIndicator stopAnimating];
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"flat-refresh"]];
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fetchEverything)];
    [view addGestureRecognizer:recognizer];
    self.refreshButton = [[UIBarButtonItem alloc] initWithCustomView:view];
    self.refreshButton.target = self;
    self.refreshButton.action = @selector(fetchEverything);
    self.navigationItem.rightBarButtonItem = self.refreshButton;
}
    
- (void)failedFetch
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self replaceRefreshButton];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not fetch goals" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)pollUntilThumbnailURLIsPresentForGoal:(Goal *)goal withTimer:(NSTimer *)timer
{
    if (goal.thumb_url) {
        [timer invalidate];
        [goal updateGraphImageThumbWithCompletionBlock:^{
            [self.tableView reloadData];
        }];
    }
    else {
        [GoalPullRequest requestForGoal:goal withSuccessBlock:^{
            if (goal.thumb_url) {
                [timer invalidate];
                [goal updateGraphImageThumbWithCompletionBlock:^{
                    [self.tableView reloadData];
                }];
            }
            else {
                [self pollUntilThumbnailURLIsPresentForGoal:goal withTimer:timer];
            }
        } withErrorBlock:^{
            NSLog(@"Error pulling goal from server");
        }];
    }
}

@end
