//
//  Goal.h
//  Beeminder
//
//  Created by Andy Brett on 7/24/12.
//  Copyright (c) 2012 Andy Brett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Datapoint, User;

@interface Goal : NSManagedObject

@property (nonatomic, retain) NSNumber * countdown;
@property (nonatomic, retain) NSNumber * date;
@property (nonatomic, retain) NSString * gtype;
@property (nonatomic, retain) NSNumber * rate;
@property (nonatomic, retain) NSNumber * serverId;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSNumber * target;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * units;
@property (nonatomic, retain) NSNumber * ephem;
@property (nonatomic, retain) NSSet *datapoints;
@property (nonatomic, retain) User *user;
@end

@interface Goal (CoreDataGeneratedAccessors)

- (void)addDatapointsObject:(Datapoint *)value;
- (void)removeDatapointsObject:(Datapoint *)value;
- (void)addDatapoints:(NSSet *)values;
- (void)removeDatapoints:(NSSet *)values;

@end
