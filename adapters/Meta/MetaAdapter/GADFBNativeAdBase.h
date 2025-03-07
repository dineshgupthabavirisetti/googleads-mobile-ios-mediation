// Copyright 2019 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADFBNativeAdBase : NSObject

/// Meta Audience Network AdChoices view.
@property(nonatomic, readonly, nonnull) FBAdOptionsView *adOptionsView;

/// Initializes a new instance with |connector| and |adapter|.
- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

- (void)loadAdOptionsView;
- (nullable NSDecimalNumber *)starRating;
- (nullable NSString *)price;
- (nullable NSString *)store;
- (nullable UIView *)adChoicesView;
- (nullable GADNativeAdImage *)icon;
- (nullable NSArray *)images;
@end
