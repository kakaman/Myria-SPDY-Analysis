--Vyshnav Kakivaya
--vyshnav@msn.com

-- Dependency graph: Name, Objs, deps, Start activity, Load activity
-- Self: comps, objects, preloads, resource info, url
--		_config, _load, _info, _parses
-- Dependencies:
-- Comp: id, type, s_time, e_time, 
-- Dep: id, a1, a2, time
-- Nodes:
-- E2D:
-- HOL: Head of Line Blocking
-- Obj: id, url, when_comp_start, download, comps
-- Download: type, s_time, id

--Dependency.pm: Generates processes the har data and output to the intermediaries.
CREATE TABLE Comp (id int, type char[50], s_time real, e_time real);
CREATE TABLE Dep (id int, a1 char[20], a2 char[20], time real);
CREATE TABLE Obj (id int, url char[50], when_comp_start real, download int, comp);
CREATE TABLE Download (id char[20], type char[50], s_time real);


process = -- Union of Obj, Comp, 
-- Gets url/start/end for data
-- Gets comps/objects/object hashes
-- Gets Hols/Preload/resourceinfo
-- Gets matched css and urls

constructParses
-- Uses Objects, resources
-- Get parses from objects and objecthashes

addIdAndD2E2Comps = -- Union of Obj and Dep amd Comp

addComps2Parses = -- Union of Parse and Comps. Any Comps that is not is in Parse

addHolDependencies = -- Add HOL dependencies and calculate the real prev

addE2DDependencies = -- Union of Dependencies and E2D

generateDependencyGraph
-- Uses self, info, parses
-- Get required resources
-- Create the Downloads
-- Add Downloads to the graph: id, url, compstart, type, stime, comps
--		Calculate host and path
-- Construct Comps
--		HTML cut/parsed into JS blocks
--		Add comp activity to objects/output dependencies
-- Construct Comps outside of parses
-- E2d Dependency info is added and e_time is modified
-- Adds the Dependency
-- Calculates computation time

WhatIfAnalysis -- Uses Parses, Resources, Comps_post, Dependency
-- Uses self, info, parses
--		url, pagestart, pageend, pageendtime, resources, parses, comps_post_1
-- Each array (resource, parse, comp) is converted into hash table
-- For every activity (from downloading html to downloading JS) change timing based on what-if policies
-- 		Calls the WhatIfAnalysisStart

WhatIfAnalysisStart  -- Utilized in the WhatIfAnalysis. 
-- Uses Self, info, parses
-- 		url, pagestart, pageEnd, pageEndTime, pageEndIf
-- Calculates a preliminary time based on policies
--		DNS, TCP, etc.
-- sets parse address, JS ids, and gets comps hash


criticalPathAnalysis
-- Uses self, info, parses
-- 

cpaFindLastActivity -- Used in criticalPathAnalysis

cpaFindInnerParser -- Used in criticalPathAnalysis

cpaFindInnerComps -- Used in criticalPathAnalysis

cpaCalculateDependencies -- Finds the dependencies that affects the URL/ Used in criticalPathAnalysis

findResourceByUrl -- Union obj and 

findCompById -- Union Comp and Obj or just Comp

findParseByID -- finds the parse given the object id


--ProcessMain.pm: Processes all the high-level results

--RawParser.pm: Takes the file and generates the various graphs.