//
//  Goal+Create.m
//  Beeminder
//
//  Created by Andy Brett on 6/24/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import "Goal+Create.h"
#import "User+CreateGoal.h"
#import "User.h"

@implementation Goal (Create)

+ (Goal *)goalWithDictionary:(NSDictionary *)goalDict 
   forUserWithUsername:(NSString *)username 
   inManagedObjectContext:(NSManagedObjectContext *)context
{
    Goal *goal = nil;
    User *user = nil;
    
    NSFetchRequest *userRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    
    userRequest.predicate = [NSPredicate predicateWithFormat:@"username = %@", username];
    NSSortDescriptor *userSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES];
    userRequest.sortDescriptors = [NSArray arrayWithObject:userSortDescriptor];
    
    NSArray *users = [context executeFetchRequest:userRequest error:NULL];
    
    if (!users || users.count > 1) {
        // error
    }
    else if (users.count == 0) {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
        user.username = username;
    }
    else {
        user = [users lastObject];
    }
    
    goal = [user addGoalFromDictionary:goalDict inManagedObjectContext:context];
    [context save:nil];
    return goal;
}

@end
