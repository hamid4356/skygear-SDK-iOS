//
//  SKYLoginCustomTokenOperation.m
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

#import "SKYLoginCustomTokenOperation.h"
#import "SKYAuthOperation_Private.h"

#import "SKYOperationSubclass.h"
#import "SKYOperation_Private.h"
#import "SKYRecordDeserializer.h"
#import "SKYRequest.h"

@interface SKYLoginCustomTokenOperation ()

@property (nonatomic, readwrite, copy) NSString *customToken;

@end

@implementation SKYLoginCustomTokenOperation

- (instancetype)initWithCustomToken:(NSString *)customToken
{
    if ((self = [super init])) {
        if (customToken == nil) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"customToken is required"
                                         userInfo:nil];
        }
        _customToken = [customToken copy];
    }
    return self;
}

+ (instancetype)operationWithCustomToken:(NSString *)customToken
{
    return [[SKYLoginCustomTokenOperation alloc] initWithCustomToken:customToken];
}

- (BOOL)requiresAPIKey
{
    return YES;
}

- (void)prepareForRequest
{
    NSDictionary *payload = @{@"token" : _customToken};
    self.request = [[SKYRequest alloc] initWithAction:@"sso:custom_token:login" payload:payload];
}

- (void)handleRequestError:(NSError *)error
{
    if (self.loginCompletionBlock) {
        self.loginCompletionBlock(nil, nil, error);
    }
}

- (void)handleAuthResponseWithUser:(SKYRecord *)user
                       accessToken:(SKYAccessToken *)accessToken
                             error:(NSError *)error
{
    if (self.loginCompletionBlock) {
        self.loginCompletionBlock(user, accessToken, error);
    }
}

@end
