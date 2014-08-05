
import json as j
import sys
import os
import csv

dataDirectory = r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro'
preLoads = []
resources = []
receivedChunk = []
computation = []
hol = []
objectHash = []

for filename in os.listdir(dataDirectory):
	print filename
	datafile = open(os.path.join(dataDirectory, filename), 'r')
	try:
		json_data = [j.loads(line) for line in datafile]
	except ValueError:
		continue
	finally: 
		datafile.close()	
	
	rID = None
	cID = 0
	holID = 0

	for line in json_data:
		
		# Sets the page variable
		if line.get('page') is not None:
			page = line['page']
		
		# Creates and fills the resources table
		if line.get('Resource') is not None:
			r = line['Resource']
			r['PageUrl'] = page
			resources.append(r)
		
		# Creates and fills the RecievedChunk table
		if line.get('Resource') is not None:
			rID = line['Resource']['id']
		elif line.get('ReceivedChunk') is not None:
			assert rID is not None
			rc = line['ReceivedChunk']
			rc['ResourceID'] = rID
			rc['PageUrl'] = page
			receivedChunk.append(rc)
		
		# Creates and fills the computation table
		if line.get('Computation') is not None:
			comp = line['Computation']
			comp['ComputationID'] = cID
			comp['PageUrl'] = page
			computation.append(comp)
			cID = cID + 1
		
		# Creates and fills the HOL list
		if line.get('HOL') is not None:
			temp = line['HOL']
			temp['holID'] = holID
			temp['PageUrl'] = page
			hol.append(temp)
			holID += 1
	
		# Creates and fills the preload list
		if line.get('Preload') is not None:
			p = line['Preload']
			p['PageUrl'] = page
			preLoads.append(p)

		# Creates and fills the ObjectHash list
		if line.get("ObjectHash") is not None:
			oh = line['ObjectHash']
			oh['PageUrl'] = page
			objectHash.append(oh)

print 'started writing'

# For more efficiency/consistency, use a list vs. dictionary to make sure the ordering is always consistent.

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\preloads.csv', 'wb') as preLoadFile:
	w = csv.DictWriter(preLoadFile, preLoads[0].keys())
	w.writeheader()	
	for row in preLoads:
		w.writerow(row)


with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\computations.csv', 'wb') as computationFile:
	w = csv.DictWriter(computationFile, computation[0].keys())
	w.writeheader()	
	for row in computation:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\receivedchunks.csv', 'wb') as chunksFile:
	w = csv.DictWriter(chunksFile, receivedChunk[0].keys())
	w.writeheader()	
	for row in receivedChunk:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\resources.csv', 'wb') as resourceFile:
	w = csv.DictWriter(resourceFile, resources[0].keys())
	w.writeheader()	
	for row in resources:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\hol.csv', 'wb') as holFile:
	w = csv.DictWriter(holFile, hol[0].keys())
	w.writeheader()	
	for row in hol:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\objecthash.csv', 'wb') as ohFile:
	w = csv.DictWriter(ohFile, objectHash[0].keys())
	w.writeheader()	
	for row in objectHash:
		w.writerow(row)