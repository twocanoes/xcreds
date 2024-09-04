//
//  DNSResolver.m
//  NoMAD
//
//  Created by Boushy, Phillip on 9/28/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

#import "DNSResolver.h"

#include <dns_util.h>
#include <net/if.h>

@interface DNSResolver ()

@property (nonatomic, assign, readwrite) BOOL				finished;
@property (nonatomic, copy,   readwrite) NSError			*error;

// Private Properties
@property (nonatomic, strong, readonly) NSMutableArray		*mutableQueryResponse;

@end

@implementation DNSResolver {
    DNSServiceRef _dnsService;
    CFSocketRef _dnsSocket;
}

@synthesize queryType = _queryType;
@synthesize queryValue = _queryValue;

@synthesize delegate = _delegate;


- init {
    self = [super init];
    if (self != nil) {
        self->_mutableQueryResponse = [[NSMutableArray alloc] init];
    }
    return self;
}

- initWithQueryType:(NSString*)queryType andValue:(NSString*)queryValue {
    assert(queryType != nil);
    assert(queryValue != nil);
    self = [super init];
    if (self != nil) {
        self->_queryType = [queryType copy];
        self->_queryValue = [queryValue copy];
        self->_mutableQueryResponse = [[NSMutableArray alloc] init];
        assert(self->_mutableQueryResponse != nil);
    }
    return self;
}
/*
 -(void)dealloc {
	[self stop];
 }
 */

-(void)startQuery {
    if (self->_dnsService == NULL) {
        self.error = nil;
        self.finished = NO;
        [_mutableQueryResponse removeAllObjects];
        [self startInternal];
    }
}

-(uint16_t)getTypeAsInt {
    uint16_t recordType;
    if ([self.queryType isEqualToString:@"SRV"]) {
        recordType = kDNSServiceType_SRV;
    } else if ([self.queryType isEqualToString:@"PTR"]) {
        recordType = kDNSServiceType_PTR;
    } else {
        recordType = kDNSServiceType_ANY;
    }
    return recordType;
}

-(void)startInternal {
    DNSServiceErrorType	err;
    const char *		dnsNameCStr;
    int					socketProtocol;
    int                 flags;

    // version (always 0), info (self because it's easy to reference?), retain, release, copyDescription
    CFSocketContext		context = { 0, (__bridge void *) self, NULL, NULL, NULL };
    CFRunLoopSourceRef	runLoopSource;

    // Start off with no errors.
    err = kDNSServiceErr_NoError;

    //Create a C string of the queryValue and verifies it is not empty.
    dnsNameCStr = [self.queryValue UTF8String];
    if (dnsNameCStr == nil) {
        err = kDNSServiceErr_BadParam;
    }
    // Create a query for the type and value
    if (err == kDNSServiceErr_NoError) {
        // perform different types of query based on queryType...
        uint16_t recordType = [self getTypeAsInt];

        //uint32_t interfaceIndex = if_nametoindex("utun1");

        // check for .local

        if ( [self.queryValue hasSuffix:@".local"]) {
            flags = (kDNSServiceFlagsReturnIntermediates + kDNSServiceFlagsTimeout);
        } else {
            flags = kDNSServiceFlagsReturnIntermediates;
        }

        // Create the DNS Query and reference it in self->_dnsService
        err = DNSServiceQueryRecord(
                                    &self->_dnsService,
                                    flags,
                                    0, // query on all interfaces.
                                    dnsNameCStr,
                                    recordType,
                                    kDNSServiceClass_IN,
                                    DNSServiceRecordCallback,
                                    (__bridge void*) self
                                    );
    }
    // Create a socket that listens for incoming messages related to the DNS Query.
    if (err == kDNSServiceErr_NoError) {
        socketProtocol = DNSServiceRefSockFD(self->_dnsService);
        self->_dnsSocket = CFSocketCreateWithNative(
                                                    NULL,
                                                    socketProtocol,
                                                    kCFSocketReadCallBack,
                                                    DNSSocketCallback,
                                                    &context
                                                    );
        // Tell the socket to close on invalidation on top of any other flags it already has set.
        // This is good and the default.
        CFSocketSetSocketFlags(
                               self->_dnsSocket,
                               CFSocketGetSocketFlags(self->_dnsSocket) & ~ (CFOptionFlags) kCFSocketCloseOnInvalidate
                               );

        runLoopSource = CFSocketCreateRunLoopSource(NULL, self->_dnsSocket, 0);
        assert(runLoopSource != NULL);

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);

        CFRelease(runLoopSource);

    }
    if (err != kDNSServiceErr_NoError) {
        [self stopQueryWithDNSServiceError:err];
    }

}

static void DNSServiceRecordCallback(
                                     DNSServiceRef       dnsService,
                                     DNSServiceFlags     flags,
                                     uint32_t            interfaceIndex,
                                     DNSServiceErrorType errorCode,
                                     const char *        fullname,
                                     uint16_t            recordType,
                                     uint16_t            recordClass,
                                     uint16_t            recordLength,
                                     const void *        recordData,
                                     uint32_t            ttl,
                                     void *              context
                                     ) {

    DNSResolver *		obj;
    obj = (__bridge DNSResolver *)context;

    if (errorCode == kDNSServiceErr_NoError) {
        // Get Interface Name
        //char *interfaceNamePtr = alloca(IF_NAMESIZE);
        //char *interfaceName = if_indextoname(interfaceIndex, interfaceNamePtr);
        //NSLog(@"Interface Index is: %u. Interface Name is: %s", interfaceIndex, interfaceName);

        //Process Record
        [obj processRecord:recordData length:recordLength];


        if ( ! (flags & kDNSServiceFlagsMoreComing) ) {
            [obj stopQueryWithError:nil];
        }
    } else {
        [obj stopQueryWithDNSServiceError:errorCode];
    }
}

static void DNSSocketCallback(
                              CFSocketRef             dnsSocket,
                              CFSocketCallBackType    type,
                              CFDataRef               address,
                              const void *            data,
                              void *                  info
                              ) {

    DNSServiceErrorType	err;
    DNSResolver *			obj;
    obj = (__bridge DNSResolver *)info;

    err = DNSServiceProcessResult(obj->_dnsService);
    if ( err != kDNSServiceErr_NoError) {
        [obj stopQueryWithDNSServiceError:err];
    }
}

-(void)processRecord:(const void *)recordData length:(NSUInteger)recordLength {
    NSMutableData *         resourceRecordData;
    dns_resource_record_t *	resourceRecord;
    uint8_t					u8;
    uint16_t                u16;
    uint32_t                u32;

    //Creating the data to send to dns_parse_resource_record.
    resourceRecordData = [NSMutableData data];

    u8 = 0;
    [resourceRecordData appendBytes:&u8 length:sizeof(u8)];
    // DNS Type
    uint16_t recordType = [self getTypeAsInt];
    u16 = htons(recordType);
    [resourceRecordData appendBytes:&u16 length:sizeof(u16)];
    // DNS Class
    u16 = htons(kDNSServiceClass_IN);
    [resourceRecordData appendBytes:&u16 length:sizeof(u16)];
    // TTL
    u32 = htonl(666);
    [resourceRecordData appendBytes:&u32 length:sizeof(u32)];
    // Record Length
    u16 = htons(recordLength);
    [resourceRecordData appendBytes:&u16 length:sizeof(u16)];
    [resourceRecordData appendBytes:recordData length:recordLength];

    //Parse the record
    resourceRecord = dns_parse_resource_record([resourceRecordData bytes], (uint32_t) [resourceRecordData length]);

    if (resourceRecord != NULL) {

        if ([self.queryType isEqualToString:@"SRV"]) {
            NSString *	target = [NSString stringWithCString:resourceRecord->data.SRV->target encoding:NSASCIIStringEncoding];
            if (target != nil) {
                NSDictionary *  result;
                NSIndexSet *    resultIndexSet;

                result = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithUnsignedInt:resourceRecord->data.SRV->priority], kSRVResolverPriority,
                          [NSNumber numberWithUnsignedInt:resourceRecord->data.SRV->weight],   kSRVResolverWeight,
                          [NSNumber numberWithUnsignedInt:resourceRecord->data.SRV->port],     kSRVResolverPort,
                          target,                                                  kSRVResolverTarget,
                          nil
                          ];
                assert(result != nil);
                
                resultIndexSet = [NSIndexSet indexSetWithIndex:self.queryResults.count];
                assert(resultIndexSet != nil);
                
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:resultIndexSet forKey:@"results"];
                [self.mutableQueryResponse addObject:result];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:resultIndexSet forKey:@"results"];
                
                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(dnsResolver:didReceiveQueryResult:)] ) {
                    [self.delegate dnsResolver:self didReceiveQueryResult:result];
                }
            }
            
        }
        
        dns_free_resource_record(resourceRecord);
    }
    
}


# pragma mark - Stop Query Methods
-(void)stopQuery {
    if (self->_dnsSocket != NULL) {
        CFSocketInvalidate(self->_dnsSocket);
        CFRelease(self->_dnsSocket);
        self->_dnsSocket = NULL;
    }
    if (self->_dnsService != NULL) {
        DNSServiceRefDeallocate(self->_dnsService);
        self->_dnsService = NULL;
    }
    self.finished = YES;
}

-(void)stopQueryWithError:(NSError *)error {
    self.error = error;
    [self stopQuery];
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(dnsResolver:didStopQueryWithError:)] ) {
        [self.delegate dnsResolver:self didStopQueryWithError:error];
    }
}

- (void)stopQueryWithDNSServiceError:(DNSServiceErrorType)errorCode
{
    NSError *   error;
    
    error = nil;
    if (errorCode != kDNSServiceErr_NoError) {
        error = [NSError errorWithDomain:kDNSResolverErrorDomain code:errorCode userInfo:nil];
    }
    [self stopQueryWithError:error];
}

# pragma mark - Results
- (NSArray *)queryResults {
    return [self.mutableQueryResponse copy];
}

@end

NSString * kSRVResolverPriority = @"priority";
NSString * kSRVResolverWeight   = @"weight";
NSString * kSRVResolverPort     = @"port";
NSString * kSRVResolverTarget   = @"target";

NSString * kDNSResolverErrorDomain = @"kDNSResolverErrorDomain";
