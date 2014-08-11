-- Tables: Computations, HOL, receivedchunks, resources, preloads, ObjectHashes, PageStart

-- At first, writing the code for only one website. If it works then modify it for the rest.

-- Input the tables into the program
computations = empty(PageUrl: string, code: int, urlRecalcStyle: string, docUrl: string, ComputationID: real, startTime: real, endTime: real, type: string); -- Use empty instead of scan to test/debug
hol = empty(PageUrl: string, code: int, column: int, url: string, docUrl: string, holID: int, type: int, row: int);
resources = empty(mimeType: string, dnsEnd: int, sslEnd: int, proxyStart: string,
						PageUrl: string, connReused: int, id: int, connectStart: int, from: string, contentLength: int, connId: int, dnsStart: ,sentTime: int,
						connectEnd: int, len: int, receiveHeadersEnd: int, sslStart: int, requestTime: real, url: string, httpStatus: int, cached: int, sendStart: int, proxyEnd: int, sendEnd: int);
receivedchunks = empty(ResourceID: int, receivedTime: real, PageUrl: string, len: int);
preloads = empty(url: string, docUrl: string, code: int, PageUrl: string, time: real);
objecthash = empty(code: int, column: int, doc: string, pos: int, url: string, PageUrl: string, chunkLen: int, tagName: string, time: real, isStartTag: int, row: int);
pagestart = empty(start: real, PageUrl: string):

-- Take out the ask.fm information out of each table
Comp = select * from computations c where c.PageUrl = "ask.fm_";
Hol = select * from hol h where h.PageUrl = "ask.fm_";
Res = select * from resources r where r.PageUrl = "ask.fm_";
RC = select * from receivedchunks rc where rc.PageUrl = "ask.fm_";
Pre = select * from preloads p where p.PageUrl = "ask.fm_";
ObjH = select * from objecthash o where o.PageUrl = "ask.fm_";
PS = select ps.Start as start from pagestart ps where ps.Start = 'ask.fm_';


-- Need to generate the parses table, parse.objects is an encoded json of objects, parse.objectsurl is similar. Some confusion
Obj = select (ObjH.time - PS.pageStart)*1000, ObjH.code, ObjH.column, ObjH.doc, ObjH.pos, ObjH.url, ObjH.PageUrl, ObjH.chunkLen, ObjH.tagName, ObjH.isStartTag, ObjH.row from ObjH, PS;

parse_1 = select Obj.time as end, Obj.code as last_code,
		  from Obj
		  where Obj.docUrl != null;

parse_2 = select Obj.time as end, Obj.code as last_code, 
		  from
		  where Obj.docUrl != null and Obj.url != null;

parse_3 = select Obj.docUrl as url, Obj.time as start, Obj.time as end, Obj.code as last_code, Obj.id as obj_id
		  from Obj
		  where 
-- Construct parses sudocode
/*
	for each object
		docUrl = object.doc
		object.time = (time - pagestart)*1000
		if(docs.docUrl)
			parse.end = obect.time
			parse.last_code = object.code
			if parse.objects
				objs = parse.objects
			add object to objs array
			if(parse.objects_hash)
				objs_hash = parse.objects_hash
			objs_hash.object.code = object
			parse.objects_hash = objs_hash
			if(object.url != null)
				if parse.objectsUrl
					objsUrl = parse.objsUrl
				add object to objsUrl
				parse.objectsUrl = objsUrl
			repeat
		if(parse.url)
			add parse to parses
		docs.docUrl = 1
		parse.url = docUrl
		parse.start = object.time
		parse.end = object.time
		parse.last_code = object.code
		parse.obj_id = parse + id
		add object to objs array
		parse.objects = objs
		objs_hash.object.code = object
		parse.objects_hash = objs_hash
		if(object.url != null)
			add object to objs_url
			parse.objectsUrl = objsUrl
		for each resource
			if(parse.url = resource.url)
				parse.critical = resource.obj_id
				parse.critical_time = resource.receivedTime
				if(parse.start < resource.receivedTime) 
					t = parse.start
				else
					t = resource.receivedTime
				pr = (
          				"id", $resource{"obj_id"},
         				"at", $t,
          				"rt", $t - $resource{"sentTime"},
          				"rs", "data",
       				 )
       		if parse.prev
       			prev = parse.prev
       		add pr to prev
       			parse.prev = prev
       		exit
       	i++
	if parse.url
		add parse to parses
	return parses
*/				

-- addComps2Parses
parse = select
		from Comp, parse
		where

parse_during_n = select 
				 from parse, Comp 
				 where parse.url = Comp.docUrl and parse.last_code != comp.code

parse_during_l = select
				 from parse, Comp
				 where parse.url = Comp.docUrl and comp.urlRecalcStyle != null and comp.urlRecalcStyle != ''

comp_post_l = select
			   from
			   where parse.url = Comp.docUrl and (comp.urlRecalcStyle != null or comp.urlRecalcStyle != '')

comp_post_n = select as comps_post_l
			   from
			   where parse.url = Comp.docUrl and (comp.urlRecalcStyle = null or comp.urlRecalcStyle = '')


-- Comp_parse sudocode
/*
for each comp
  for each parse
	if (parse.url = comp.docUrl)
		if(parse.last_code != comp.code)
			if(parse.during_n)
				comp_during_n = parse.during_n
			else
				comp_during_n = ();
			push comp into comps_during_n
			parse.during_n = comp_during_n
		if(comp.urlRecalcStyle != null && comp.urlRecalcStyle != "")
			if(parse.during_l)
				comps_during_l = parse.during_l
			else
				comps_during_l = ();
			push comp into comps_during_1
			parse.during_l = comps_during_l	
		else
			if (comp.urlRecalcStyle == null || comp.urlRecalcStyle == '')
				push comp into comps_post_n
			else
				push comp into comps_post_l
self.parse = parses
self._comps_post_n = comps_post_n
selc._comps_post_l = comps_post_l
*/

-- Sets the resource table to proper values. Corresponds to addId2Resources
Res = select "Download" + Res.id as ObjId, (Res.sentTime - PS.start)*1000 as sentTime,
			 (Res.requestTime - PS.start)*1000 as requestTime, (Res.receivedTime - PS.start)*1000 as receivedTime,
			 Res.requestTime - Res.receivedTime as blocking, 0 as proxy, 0 as dns, 0 as conn, 0 as ssl, 0 as send, 0 as receiveFirst, 0 as receiveLast
	  from Res, PS;

-- Sets comp. Make sure to create a table with D2E, critical, critical_time. Might need more implementation. Corresponds to addIdAndD2E2Comps
Comp = select "comp_" + Comp.id as obj_id, (Comp.startTime - PS.pageStart)*1000 as startTime, (Comp.endTime - PS.pageStart)*1000 as endTime,
			  Comp.D2E, Comp.critical, Comp.critical_time, Comp.urlRecalcStyle
	   from Comp, PS
	   where Comp.urlRecalcStyle = null
	   union
	   select "comp_" + Comp.id as obj_id, (Comp.startTime - PS.pageStart)*1000 as startTime, (Comp.endTime - PS.pageStart)*1000 as endTime,
			  Comp.D2E = Res.obj_id, Comp.critical = Res.obj_id, Comp.critical_time = Res.receivedTime, Comp.urlRecalcStyle
	   from Comp, PS, Res
	   where Comp.urlRecalcStyle = Res.url;

-- Corresponds to addComps2Parses

-- Creates the CompHol table Corresponds to addHolDependencies
CompHol = select * from Hol, Comp where Comp.docUrl = Hol.docUrl and Comp.urlRecalcStyle = Hol.url;


-- addE2DDependencies
img_resource = 

preload_dep_1 = select (Pre.time - PS.start)*1000 as time, Pre.url, Pre.docUrl, Pre.code, Pre.PageUrl
		 	  from Pre, Res, PS
			  where abs(Pre.time - Res.sentTime) < 1 and Pre.url = Res.url;

-- Preload_dep_1 sudo code
/*
	if ((Pre.time - Res.sentTime) < 1 or (Pre.time - Res.sentTime) > -1) and Pre.url == Res.url
	{
		time = (Pre.time - PS.start)*1000
		preload_dep(preload.url) = preload
	}
*/

preload_dep_2 = select parse.object_hash.preload_dep_1.code
			  from Res, preload_dep_1, PS, parse
			  where parse.url = preload_dep_1.docUrl and parse.object_hash = Null

-- Preload_dep_2 sudo code
/*for each parse
      if parse.url = preload.docUrl and parse.object_hash = Null 
      {
      	objects = parse.objects_hash
      	obj = objects.preload.code
      }*/