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
Comp = select * from computations c where c.PageUrl = "ask.fm";
Hol = select * from hol h where h.PageUrl = "ask.fm";
Res = select * from resources r where r.PageUrl = "ask.fm";
RC = select * from receivedchunks rc where rc.PageUrl = "ask.fm";
Pre = select * from preloads p where p.PageUrl = "ask.fm";


-- Generates the large "combo" table
Combo = select * from Comp, Pre, RC, Res, Hol;

-- Creates the "download" from the Resources
download = select s_time, id, type from Res;

-- Creates the "comps" table from the computations, Resources

comps = select s_time, time, "r1_c1" as id, type, e_time from Res, Comp where Res.sentTime = Comp.startTime; -- The ID has to change/increment for each one.