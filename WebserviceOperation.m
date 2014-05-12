
// WebserviceOperation.m
//Created Via PKTSVITS



#import "WebserviceOperation.h"
#import "VideoPlaybackAppDelegate.h"
#import "ZipArchive.h"
#import "VideoPlaybackAppDelegate.h"



//#import "JSON/JSON.h"


@implementation WebserviceOperation
@synthesize	_delegate;
@synthesize _callback;

//-(void)dealloc{
//	[_delegate release];
//	[super dealloc];
//}

-(id)initWithDelegate:(id)delegate callback:(SEL)callback{
	if (self = [super init]) {
		self._delegate = delegate;
		self._callback = callback;
	}
	return self;
}
-(void)getXmlContent
{
    responseData = [[NSMutableData alloc] init] ;
    
    NSString *methodName=[NSString stringWithFormat:@"GetXmlAttribute"];
    
    NSString *soapMessage=[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body>\n<%@ xmlns=\"http://tempuri.org/\"/>\n</soap:Body>\n</soap:Envelope>",methodName];
    NSString *SoapAction=[NSString stringWithFormat:@"\"http://tempuri.org/%@\"",methodName];
    
    
    NSURL *url = [NSURL URLWithString:@"http://ar.techvalens.net/SoapService/WebService.asmx"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
    
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue: SoapAction forHTTPHeaderField:@"SOAPAction"];
    [request addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
//    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    NSError *err;
    NSURLResponse *res;
    NSData *tempDataResponceAttri = [[NSURLConnection sendSynchronousRequest:request returningResponse:&res error:&err] mutableCopy];
    
//    NSString *myString = [[NSString alloc] initWithData:webDataRes encoding:NSUTF8StringEncoding];
//
//    
//    NSXMLParser *parser=[[NSXMLParser alloc]  initWithData:[myString dataUsingEncoding:NSUTF8StringEncoding]];
//    [parser setDelegate:self];
//    [parser parse];
    
    
    if([tempDataResponceAttri isKindOfClass:[NSError class]]) {
        
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error" message:@"An error occurred. Please try again later. " delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        //return;
        
    }
    
    NSString* newStr = [[NSString alloc] initWithData:tempDataResponceAttri encoding:NSUTF8StringEncoding];
    
    newStr = [[[[[[[[[[[newStr
                        //                              stringByReplacingOccurrencesOfString:@"&amp;amp;" withString:@"&"]
                        stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]
                       stringByReplacingOccurrencesOfString:@"&#x27;" withString:@"'"]
                      stringByReplacingOccurrencesOfString:@"&#x39;" withString:@"'"]
                     stringByReplacingOccurrencesOfString:@"&#x92;" withString:@"'"]
                    stringByReplacingOccurrencesOfString:@"&#x96;" withString:@"'"]
                   stringByReplacingOccurrencesOfString:@"&#27;" withString:@"'"]
                  stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"]
                 stringByReplacingOccurrencesOfString:@"&#92;" withString:@"'"]
                stringByReplacingOccurrencesOfString:@"&#96;" withString:@"'"]
               //                    stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]
               stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"]
              stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    
    
    NSXMLParser *parser=[[NSXMLParser alloc]  initWithData:[newStr dataUsingEncoding:NSUTF8StringEncoding]];
    [parser setDelegate:self];
    [parser parse];
    
}
-(void)getZip
{
    responseData = [[NSMutableData alloc] init] ;
    
    NSString *methodName=[NSString stringWithFormat:@"DownloadXmlFile"];
    
    NSString *soapMessage=[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body>\n<%@ xmlns=\"http://tempuri.org/\"/>\n</soap:Body>\n</soap:Envelope>",methodName];
    NSString *SoapAction=[NSString stringWithFormat:@"\"http://tempuri.org/%@\"",methodName];
    
    
    NSURL *url = [NSURL URLWithString:@"http://ar.techvalens.net/SoapService/WebService.asmx"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
    
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue: SoapAction forHTTPHeaderField:@"SOAPAction"];
    [request addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *err;
    NSURLResponse *res;
    NSData *webDataRes = [[NSURLConnection sendSynchronousRequest:request returningResponse:&res error:&err] mutableCopy];
   
    NSArray *zipPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *zipDocumentDirectory = [zipPath objectAtIndex:0];
    
//    NSString *zipDocumentDirectory = [[NSBundle mainBundle] resourcePath];
    
    NSString *zipSetPath = [zipDocumentDirectory stringByAppendingPathComponent:@"zipData.zip"];
    
    NSArray *nsarray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:zipDocumentDirectory error:NULL];
    NSLog(@"Document Directory Contents==%@",nsarray);
    NSLog(@"Document Directory ==%@",zipDocumentDirectory);
    
    
    [webDataRes writeToFile:zipSetPath atomically:YES];
    
    ZipArchive *z = [[ZipArchive alloc] init];
    
    [z UnzipOpenFile:zipSetPath];
    [z UnzipFileTo:zipDocumentDirectory overWrite:YES];
    [z UnzipCloseFile];
    
//    NSArray *nsarray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:zipDocumentDirectory error:NULL];
    
//    NSString *zipSetPathNew1 = [zipDocumentDirectory stringByAppendingPathComponent:@"techvalensdemo.xml"];
//    NSString *zipSetPathNew2 = [zipDocumentDirectory stringByAppendingPathComponent:@"techvalensdemo.dat"];
//    
//    xmlData=[[NSData alloc]initWithContentsOfFile:zipSetPathNew1];
//    
//    datData =[[NSData alloc]initWithContentsOfFile:zipSetPathNew2];
//    
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *documentsPath = [documentsDirectory stringByAppendingPathComponent:@"techvalensdemo.xml"];
//    
//    NSString *string1 = [[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease];
//    NSString *string2 = [[[NSString alloc] initWithData:datData encoding:NSUTF8StringEncoding] autorelease];
//    
//    [xmlData writeToFile:documentsPath atomically:YES];
//    
//    NSString *documentsPathDat = [documentsDirectory stringByAppendingPathComponent:@"techvalensdemo.dat"];
//    
//    [datData writeToFile:documentsPathDat atomically:YES];
    
//    QCARutils *qUtils = [QCARutils getInstance];
//    
//    for (int i=0; i<[attributes count]; i++) {
//        [qUtils addTargetName:[attributes objectAtIndex:i] atPath:documentsPath];
//    }
    
    [[VideoPlaybackAppDelegate sharedInstance] allFix];

}
-(void)getAllService
{
    [VideoPlaybackAppDelegate showHud:@"Loading..."];

    responseData = [[NSMutableData alloc] init] ;
    
    NSString *methodName=[NSString stringWithFormat:@"GetAllWebservice"];
    
    NSString *soapMessage=[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body>\n<%@ xmlns=\"http://tempuri.org/\"/>\n</soap:Body>\n</soap:Envelope>",methodName];
    NSString *SoapAction=[NSString stringWithFormat:@"\"http://tempuri.org/%@\"",methodName];
    
    
    NSURL *url = [NSURL URLWithString:@"http://ar.techvalens.net/SoapService/WebService.asmx"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
    
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue: SoapAction forHTTPHeaderField:@"SOAPAction"];
    [request addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
    

}

#pragma mark NSURLDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([self._delegate respondsToSelector:self._callback]) {
		[self._delegate performSelector:self._callback withObject:error];
	}else {
		NSLog(@"Callback is not responding.");
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {		
	
      NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    if (responseString.length>100) {
        NSRange range1=[responseString rangeOfString:@"{"];
        responseString=[responseString substringFromIndex:range1.location];
        
        NSRange range2=[responseString rangeOfString:@"</"];
        
        responseString=[responseString substringToIndex:range2.location];
    }
    
    
  
     NSLog(@"Response=%@",responseString);
    
    responseString=[responseString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    
    NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    NSError * error = nil;
    
    
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    //NSLog(@"json=%@",(NSMutableDictionary*)json);
 
    
    if (json==nil){
        if ([self._delegate respondsToSelector:self._callback]) {
            [self._delegate performSelector:self._callback withObject:error];
        }
    }
    else{
        if([self._delegate respondsToSelector:self._callback]) {
            [self._delegate performSelector:self._callback withObject:json];
        }else{
            NSLog(@"Callback is not responding.");
        }
}
}

#pragma mark NSXML Parser Delegates.
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"ImageTarget"])
    {
        [[VideoPlaybackAppDelegate sharedInstance].arrayForImageTarget addObject:[attributeDict objectForKey: @"name"]];
    }
    
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)str
{
}
-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    [VideoPlaybackAppDelegate killHud];
    [self._delegate performSelector:self._callback withObject:nil];
}

@end

