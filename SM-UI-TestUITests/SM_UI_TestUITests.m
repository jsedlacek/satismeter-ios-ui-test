//
//  SM_UI_TestUITests.m
//  SM-UI-TestUITests
//
//  Created by Jakub Sedlacek on 09/09/16.
//  Copyright © 2016 Jakub Sedlacek. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"

@interface SM_UI_TestUITests : XCTestCase
@property (nonatomic, strong) XCUIApplication *app;
@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) NSDictionary *response;
@end

@implementation SM_UI_TestUITests

- (void)setUp {
    [super setUp];
    
    self.webServer = [[GCDWebServer alloc] init];
    
    [self.webServer addHandlerForMethod: @"POST"
                                   path: @"/api/widget"
                           requestClass: [GCDWebServerRequest class]
                           processBlock: ^GCDWebServerResponse *(GCDWebServerRequest* request) {
                               NSDictionary* data = @{ @"widget": @{
                                                               @"visible": @YES,
                                                               @"colorCode": @"#ff4981",
                                                               @"serviceName": @"Test app",
                                                               @"translation": @{
                                                                       @"US": @"us",
                                                                       @"HOW_LIKELY_US": @"How likely are you to recommend us to your friends and colleagues?",
                                                                       @"HOW_LIKELY": @"How likely are you to recommend %s to your friends and colleagues?",
                                                                       @"UNLIKELY": @"Not at all likely",
                                                                       @"LIKELY": @"Extremely likely",
                                                                       @"FOLLOWUP": @"What could we do to improve?",
                                                                       @"DISMISS": @"Close",
                                                                       @"SUBMIT": @"Submit Feedback",
                                                                       @"THANKS": @"Thank you for your feedback!",
                                                                       @"FILLED": @"You have already filled the survey."
                                                                       },
                                                               @"showPoweredBy": @YES
                                                               }};
                               return [GCDWebServerDataResponse responseWithJSONObject:data];
                           }];
    
    [self.webServer addHandlerForMethod: @"POST"
                                   path: @"/api/responses"
                           requestClass: [GCDWebServerDataRequest class]
                           processBlock: ^GCDWebServerResponse *(GCDWebServerDataRequest* request) {
                               self.response = request.jsonObject;
                               
                               return [GCDWebServerDataResponse responseWithStatusCode:204];
                           }];
    
    [self.webServer startWithOptions:@{ GCDWebServerOption_Port: @(8080),
                                        GCDWebServerOption_AutomaticallySuspendInBackground: @NO }
                               error:NULL];
    
    self.continueAfterFailure = NO;
    
    self.app = [[XCUIApplication alloc] init];
    [self.app launch];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [self.webServer stop];
    
}

- (void)testExample {
    XCUIElement *label = self.app.staticTexts[@"How likely are you to recommend Test app to your friends and colleagues?"];
    NSPredicate *exists = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:exists evaluatedWithObject:label handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssert(label.exists);
    
    [[[[self.app.scrollViews.otherElements containingType:XCUIElementTypeStaticText identifier:@"How likely are you to recommend Test app to your friends and colleagues?"] childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:0] tap];

    XCUIElementQuery *scrollViewsQuery = self.app.scrollViews;
    [scrollViewsQuery.otherElements.buttons[@"Submit Feedback"] tap];

    XCUIElement *thanks = self.app.staticTexts[@"Thank you for your feedback!"];
    NSPredicate *thanksExists = [NSPredicate predicateWithFormat:@"exists == 1"];
    [self expectationForPredicate:thanksExists evaluatedWithObject:thanks handler:nil];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssert(thanks.exists);
    
    XCTAssertEqual([self.response[@"rating"] integerValue], 5);

}

@end
