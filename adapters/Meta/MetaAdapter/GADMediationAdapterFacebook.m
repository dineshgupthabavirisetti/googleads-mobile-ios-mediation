// Copyright 2018 Google Inc.
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

#import "GADMediationAdapterFacebook.h"
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "GADFBBannerRenderer.h"
#import "GADFBInterstitialRenderer.h"
#import "GADFBNativeRenderer.h"
#import "GADFBNetworkExtras.h"
#import "GADFBRewardedInterstitialRenderer.h"
#import "GADFBRewardedRenderer.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebook.h"
#import "GADMAdapterFacebookConstants.h"

@implementation GADMediationAdapterFacebook {
  /// Meta Audience Network rewarded ad wrapper.
  GADFBRewardedRenderer *_rewardedAd;
  /// Meta Audience Network native ad wrapper.
  GADFBNativeRenderer *_native;
  /// Meta Audience Network interstitial ad wrapper.
  GADFBInterstitialRenderer *_interstitial;
  /// Meta Audience Network banner ad wrapper.
  GADFBBannerRenderer *_banner;
  /// Meta Audience Network rewarded interstitial ad wrapper.
  GADFBRewardedInterstitialRenderer *_rewardedInterstitialAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSCAssert(completionHandler, @"Completion handler must not be nil.");
  NSMutableSet<NSString *> *placementIds = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *placementId = [self getPlacementIDFromCredentials:cred];
    if (placementId) {
      GADMAdapterFacebookMutableSetAddObject(placementIds, placementId);
    }
  }

  FBAdInitSettings *fbSettings = [[FBAdInitSettings alloc]
      initWithPlacementIDs:[placementIds allObjects]
          mediationService:[NSString stringWithFormat:@"GOOGLE_%@:%@",
                                                      GADMobileAds.sharedInstance.sdkVersion,
                                                      GADMAdapterFacebookVersion]];

  [FBAudienceNetworkAds initializeWithSettings:fbSettings
                             completionHandler:^(FBAdInitResults *_Nonnull results) {
                               NSError *error = nil;
                               if (!results.success) {
                                 error = GADFBErrorWithCodeAndDescription(
                                     GADFBErrorInitializationFailure, results.message);
                               }
                               completionHandler(error);
                             }];
}

+ (NSString *)getPlacementIDFromCredentials:(GADMediationCredentials *)credentials {
  NSString *placementID = credentials.settings[GADMAdapterFacebookBiddingPubID];
  if (!placementID) {
    placementID = credentials.settings[GADMAdapterFacebookPubID];
  }
  return placementID;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [GADMAdapterFacebookVersion componentsSeparatedByString:@"."];
  if (components.count == 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADFBNetworkExtras class];
}

+ (GADVersionNumber)adSDKVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [FB_AD_SDK_VERSION componentsSeparatedByString:@"."];
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else {
    NSLog(@"Unexpected Meta Audience Network version string: %@. Returning 0 for adSDKVersion.",
          FB_AD_SDK_VERSION);
  }
  return version;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  completionHandler([FBAdSettings bidderToken], nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  if (!adConfiguration.bidResponse) {
    NSLog(@"%@", GADMAdapterFacebookWaterfallDeprecationMessage);
  }
  if (adConfiguration.childDirectedTreatment) {
    GADMAdapterFacebookSetMixedAudience(adConfiguration.childDirectedTreatment);
  }

  _banner = [[GADFBBannerRenderer alloc] init];
  [_banner renderBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if (!adConfiguration.bidResponse) {
    NSLog(@"%@", GADMAdapterFacebookWaterfallDeprecationMessage);
  }
  if (adConfiguration.childDirectedTreatment) {
    GADMAdapterFacebookSetMixedAudience(adConfiguration.childDirectedTreatment);
  }

  _interstitial = [[GADFBInterstitialRenderer alloc] init];
  [_interstitial renderInterstitialForAdConfiguration:adConfiguration
                                    completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!adConfiguration.bidResponse) {
    NSLog(@"%@", GADMAdapterFacebookWaterfallDeprecationMessage);
  }
  if (adConfiguration.childDirectedTreatment) {
    GADMAdapterFacebookSetMixedAudience(adConfiguration.childDirectedTreatment);
  }
  _rewardedAd = [[GADFBRewardedRenderer alloc] init];
  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

- (void)loadRewardedInterstitialAdForAdConfiguration:
            (GADMediationRewardedAdConfiguration *)adConfiguration
                                   completionHandler:(GADMediationRewardedLoadCompletionHandler)
                                                         completionHandler {
  if (!adConfiguration.bidResponse) {
    NSLog(@"%@", GADMAdapterFacebookWaterfallDeprecationMessage);
  }
  if (adConfiguration.childDirectedTreatment) {
    GADMAdapterFacebookSetMixedAudience(adConfiguration.childDirectedTreatment);
  }
  _rewardedInterstitialAd = [[GADFBRewardedInterstitialRenderer alloc] init];
  [_rewardedInterstitialAd loadRewardedAdForAdConfiguration:adConfiguration
                                          completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  if (!adConfiguration.bidResponse) {
    NSLog(@"%@", GADMAdapterFacebookWaterfallDeprecationMessage);
  }
  if (adConfiguration.childDirectedTreatment) {
    GADMAdapterFacebookSetMixedAudience(adConfiguration.childDirectedTreatment);
  }
  _native = [[GADFBNativeRenderer alloc] init];
  [_native renderNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
