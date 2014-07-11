--Vyshnav Kakivaya
--vyshnav@msn.com

--Attempt at implementing the perl in SQL before converting it into MyriaL

-- Dependency graph: Name, Objs, deps, Start activity, Load activity
-- Self: comps, objects, preloads, resource info, url, 
-- Dependencies:
-- Comp: id, type, s_time, e_time, 
-- Dep: id, a1, a2, time
-- Nodes:
-- E2D: 
-- Obj: id, url, when_comp_start, download, comps
-- Download: type, s_time, id

CREATE TABLE Comp (id int, type char[50], s_time real, e_time real);
CREATE TABLE Dep (id int, a1, a2, time real);
CREATE TABLE Obj (id int, url char[50], when_comp_start real, download int, comp);
CREATE TABLE Download (id char[20], type char[50], s_time real);

