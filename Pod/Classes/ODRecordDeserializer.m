//
//  ODRecordDeserializer.m
//  askq
//
//  Created by Patrick Cheung on 9/2/15.
//  Copyright (c) 2015 Rocky Chan. All rights reserved.
//

#import "ODRecordDeserializer.h"
#import "ODRecord.h"
#import "ODUserRecordID.h"
#import "ODRecordID.h"
#import "ODUser.h"
#import "ODRecordSerialization.h"
#import "ODReference.h"
#import "ODDataSerialization.h"

@implementation ODRecordDeserializer

+ (instancetype)deserializer
{
    return [[ODRecordDeserializer alloc] init];
}


- (ODRecord *)recordWithDictionary:(NSDictionary *)obj
{
    NSMutableDictionary *recordData = [NSMutableDictionary dictionary];
    [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![(NSString *)key hasPrefix:@"_"]) {
            [recordData setObject:[ODDataSerialization deserializeObjectWithValue:obj]
                           forKey:key];
        }
    }];
    
    ODRecordID *recordID = [[ODRecordID alloc] initWithCanonicalString:obj[ODRecordSerializationRecordIDKey]];
    ODRecord *record;
    if ([recordID.recordType isEqualToString:@"user"]) {
        recordID = [[ODUserRecordID alloc] initWithCanonicalString:recordID.canonicalString];
        record = [[ODUser alloc] initWithRecordID:recordID
                                             data:recordData];
    } else {
        record = [[ODRecord alloc] initWithRecordID:recordID
                                               data:recordData];
    }
    
    return record;
}

@end
