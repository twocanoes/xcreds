//
//  DNSResolver.h
//  NoMAD
//
//  Created by Boushy, Phillip on 9/28/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dns_sd.h>

@protocol DNSResolverDelegate;

@interface DNSResolver : NSObject

- initWithQueryType:(NSString*)queryType andValue:(NSString*)queryValue;

// Setup by init...
@property NSString *												queryType; //SRV,
@property NSString *												queryValue; // hostname, IP, or SRV url
// Changeable any time.
@property (nonatomic, weak,   readwrite) id<DNSResolverDelegate>	delegate;

// Properties set by class methods.
@property (nonatomic, assign, readonly) BOOL						finished;   // observable
@property (nonatomic, copy,   readonly) NSError *					error;      // observable
@property (readonly) NSArray *										queryResults;

-(void)startQuery;
-(void)stopQuery;
-(void)stopQueryWithError:(NSError *)error;

@end


// Keys for the dictionaries in the results array:

extern NSString * kSRVResolverPriority;     // NSNumber, host byte order
extern NSString * kSRVResolverWeight;       // NSNumber, host byte order
extern NSString * kSRVResolverPort;         // NSNumber, host byte order
extern NSString * kSRVResolverTarget;       // NSString

extern NSString * kDNSResolverErrorDomain; //Figure out what the heck this means...




@protocol DNSResolverDelegate <NSObject>

@optional

- (void)dnsResolver:(DNSResolver *)resolver didReceiveQueryResult:(NSDictionary *)queryResult;
// Called when we've successfully receive an answer.  The result parameter is a copy
// of the dictionary that we just added to the results array.  This callback can be
// called multiple times if there are multiple results.  You learn that the last
// result was delivered by way of the -srvResolver:didStopWithError: callback.

- (void)dnsResolver:(DNSResolver *)resolver didStopQueryWithError:(NSError *)error;
// Called when the query stops (except when you stop it yourself by calling -stop),
// either because it's received all the results (error is nil) or there's been an
// error (error is not nil).

@end
