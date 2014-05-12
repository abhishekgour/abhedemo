//Created Via PKTSVITS
//  WebserviceOperation.h
#import <Foundation/Foundation.h>
@interface WebserviceOperation : NSObject<NSURLConnectionDelegate,NSXMLParserDelegate> {
	NSMutableData *responseData;
	id _delegate;
	SEL _callback;
    NSData *xmlData;
    NSData *datData;
}

@property(nonatomic, retain) 	id _delegate;
@property(nonatomic, assign) 	SEL _callback;

-(void)getAllService;
-(void)getZip;
-(void)getXmlContent;

-(id)initWithDelegate:(id)delegate callback:(SEL)callback;
@end
