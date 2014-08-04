-- Tables: Computations, HOL, receivedchunks, resources, preloads

-- At first, writing the code for only one website. If it works then modify it for the rest.

-- Input the tables into the program
computations = empty(PageUrl: string, code: int, urlRecalcStyle: string, docUrl: string, ComputationID: real, startTime: real, endTime: real, type: string); -- Use empty instead of scan to test/debug
hol = empty(PageUrl: string, code: int, column: int, url: string, docUrl: string, holID: int, type: int, row: int);
resources = empty(mimeType: string, dnsEnd: int, sslEnd: int, proxyStart: string,
						PageUrl: string, connReused: int, id: int, connectStart: int, from: string, contentLength: int, connId: int, dnsStart: ,sentTime: int,
						connectEnd: int, len: int, receiveHeadersEnd: int, sslStart: int, requestTime: real, url: string, httpStatus: int, cached: int, sendStart: int, proxyEnd: int, sendEnd: int);
receivedchunks = empty(ResourceID: int, receivedTime: real, PageUrl: string, len: int);
preloads = empty(url: string, docUrl: string, code: int, PageUrl: string, time: real);

-- Take out the ask.fm information out of each table
AskComp = select PageUrl from computations c where c.PageUrl = "ask.fm";
AskHol = select PageUrl from hol h where h.PageUrl = "ask.fm";
AskRes = select PageUrl from resources r where r.PageUrl = "ask.fm";
AskRC = select PageUrl from receivedchunks rc where rc.PageUrl = "ask.fm";
AskPre = select PageUrl from preloads p where p.PageUrl = "ask.fm";

-- Creates the downloads