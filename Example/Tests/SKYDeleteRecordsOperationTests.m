//
//  SKYDeleteRecordsOperationTests.m
//  SKYKit
//
//  Copyright 2015 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <SKYKit/SKYKit.h>

SpecBegin(SKYDeleteRecordsOperation)

    describe(@"delete", ^{
        __block SKYContainer *container = nil;
        __block SKYDatabase *database = nil;

        beforeEach(^{
            container = [SKYContainer testContainer];
            [container.auth updateWithUserRecordID:@"USER_ID"
                                       accessToken:[[SKYAccessToken alloc]
                                                       initWithTokenString:@"ACCESS_TOKEN"]];
            database = [container publicCloudDatabase];
        });

        it(@"single record", ^{
            NSString *recordID = @"book1";
            SKYDeleteRecordsOperation *operation =
                [SKYDeleteRecordsOperation operationWithRecordType:@"book" recordIDs:@[ recordID ]];
            operation.database = database;
            operation.container = container;
            [operation makeURLRequestWithError:nil];
            SKYRequest *request = operation.request;
            expect([request class]).to.beSubclassOf([SKYRequest class]);
            expect(request.action).to.equal(@"record:delete");
            expect(request.accessToken).to.equal(container.auth.currentAccessToken);
            expect(request.payload[@"ids"]).to.equal(@[ @"book/book1" ]);
            expect(request.payload[@"records"]).to.equal(@[ @{
                @"_recordType" : @"book",
                @"_recordID" : recordID,
            } ]);
            expect(request.payload[@"database_id"]).to.equal(database.databaseID);
        });

        it(@"multiple record", ^{
            NSString *recordID1 = @"book1";
            NSString *recordID2 = @"book2";
            SKYDeleteRecordsOperation *operation =
                [SKYDeleteRecordsOperation operationWithRecordType:@"book"
                                                         recordIDs:@[ recordID1, recordID2 ]];
            operation.database = database;
            operation.container = container;
            [operation makeURLRequestWithError:nil];
            SKYRequest *request = operation.request;
            expect([request class]).to.beSubclassOf([SKYRequest class]);
            expect(request.action).to.equal(@"record:delete");
            expect(request.accessToken).to.equal(container.auth.currentAccessToken);
            expect(request.payload[@"ids"]).to.equal(@[ @"book/book1", @"book/book2" ]);
            expect(request.payload[@"records"]).to.equal(@[
                @{
                    @"_recordType" : @"book",
                    @"_recordID" : recordID1,
                },
                @{
                    @"_recordType" : @"book",
                    @"_recordID" : recordID2,
                }
            ]);
            expect(request.payload[@"database_id"]).to.equal(database.databaseID);
        });

        it(@"set atomic", ^{
            SKYDeleteRecordsOperation *operation =
                [SKYDeleteRecordsOperation operationWithRecordType:@"book" recordIDs:@[]];
            operation.atomic = YES;

            operation.database = database;
            operation.container = container;
            [operation makeURLRequestWithError:nil];

            SKYRequest *request = operation.request;
            expect(request.payload[@"atomic"]).to.equal(@YES);
        });

        it(@"make request", ^{
            NSString *recordID1 = @"book1";
            NSString *recordID2 = @"book2";
            SKYDeleteRecordsOperation *operation =
                [SKYDeleteRecordsOperation operationWithRecordType:@"book"
                                                         recordIDs:@[ recordID1, recordID2 ]];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSDictionary *parameters = @{
                        @"request_id" : @"REQUEST_ID",
                        @"database_id" : database.databaseID,
                        @"result" : @[
                            @{
                                @"_recordType" : @"book",
                                @"_recordID" : @"book1",
                                @"_type" : @"record",
                            },
                            @{
                                @"_recordType" : @"book",
                                @"_recordID" : @"book2",
                                @"_type" : @"record",
                            },
                        ],
                    };
                    NSData *payload =
                        [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                    return
                        [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
                }];

            waitUntil(^(DoneCallback done) {
                operation.deleteRecordsCompletionBlock =
                    ^(NSArray<SKYRecordResult<SKYRecord *> *> *_Nullable results,
                      NSError *_Nullable operationError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            expect(results).to.haveCountOf(2);
                            expect(results[0].value.recordID).to.equal(recordID1);
                            expect(results[1].value.recordID).to.equal(recordID2);
                            expect(operationError).to.beNil();
                            done();
                        });
                    };
                [database executeOperation:operation];
            });
        });

        it(@"pass error", ^{
            NSString *recordID1 = @"book1";
            NSString *recordID2 = @"book2";
            SKYDeleteRecordsOperation *operation =
                [SKYDeleteRecordsOperation operationWithRecordType:@"book"
                                                         recordIDs:@[ recordID1, recordID2 ]];
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    return [OHHTTPStubsResponse
                        responseWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                              code:0
                                                          userInfo:nil]];
                }];

            waitUntil(^(DoneCallback done) {
                operation.deleteRecordsCompletionBlock =
                    ^(NSArray<SKYRecordResult<SKYRecord *> *> *_Nullable results,
                      NSError *_Nullable operationError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            expect(operationError).toNot.beNil();
                            done();
                        });
                    };
                [database executeOperation:operation];
            });
        });

        it(@"per block", ^{
            NSString *recordID1 = @"book1";
            NSString *recordID2 = @"book2";
            SKYDeleteRecordsOperation *operation =
                [SKYDeleteRecordsOperation operationWithRecordType:@"book"
                                                         recordIDs:@[ recordID1, recordID2 ]];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return YES;
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSDictionary *parameters = @{
                        @"request_id" : @"REQUEST_ID",
                        @"database_id" : database.databaseID,
                        @"result" : @[
                            @{
                                @"_recordType" : @"book",
                                @"_recordID" : @"book1",
                                @"_type" : @"record"
                            },
                            @{
                                @"_recordType" : @"book",
                                @"_recordID" : @"book2",
                                @"_type" : @"error",
                                @"code" : @(SKYErrorUnexpectedError),
                                @"message" : @"An error.",
                                @"name" : @"UnexpectedError",
                            }
                        ]
                    };
                    NSData *payload =
                        [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                    return
                        [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
                }];

            waitUntil(^(DoneCallback done) {
                operation.deleteRecordsCompletionBlock =
                    ^(NSArray<SKYRecordResult<SKYRecord *> *> *_Nullable results,
                      NSError *_Nullable operationError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            expect(results).to.haveCountOf(2);
                            expect(results[0].value.recordID).to.equal(recordID1);
                            expect(results[1].error).notTo.beNil();
                            expect(operationError).to.beNil();
                            done();
                        });
                    };
                [database executeOperation:operation];
            });
        });

        afterEach(^{
            [OHHTTPStubs removeAllStubs];
        });
    });

SpecEnd
