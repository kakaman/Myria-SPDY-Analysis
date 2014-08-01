
import json as j
import sys
import os

dataDirectory = r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro'
preLoads = []
resources = []
receivedChunk = []
computation = []
hol = []

for filename in os.listdir(dataDirectory):
	print filename
	datafile = open(os.path.join(dataDirectory, filename), 'r')
	try:
		json_data = [j.loads(line) for line in datafile]
	except ValueError:
		continue
	finally: 
		datafile.close()	
	for line in json_data:
		if 'page' in line:
			page = line['page']

	# Creates and fills the resources table
	for line in json_data:
		if 'Resource' in line:
			r = line['Resource']
			r['PageUrl'] = page
			resources.append(r)

	# Creates and fills the RecievedChunk table
	rID = None
	for line in json_data:
		if 'Resource' in line:
			rID = line['Resource']['id']
		elif 'ReceivedChunk' in line:
			assert rID is not None
			rc = line['ReceivedChunk']
			rc['ResourceID'] = rID
			rc['PageUrl'] = page
			receivedChunk.append(rc)

	# Creates and fills the computation table
	cID = 0
	for line in json_data:
		if 'Computation' in line:
			comp = line['Computation']
			comp['ComputationID'] = cID
			comp['PageUrl'] = page
			computation.append(comp)
			cID = cID + 1

	# Creates and fills the HOL list
	holID = 0
	for line in json_data:
		if 'HOL' in line:
			temp = line['HOL']
			temp['holID'] = holID
			temp['PageUrl'] = page
			hol.append(temp)
			holID += 1
	# Creates and fills the preload list
	for line in json_data:
		if 'Preload' in line:
			p = line['Preload']
			p['PageUrl'] = page
			preLoads.append(p)

import csv

print 'started writing'

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

# with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\preloads.csv', 'wb') as preLoadFile:
# 	w = csv.writer(preLoadFile)	
# 	w.writerow(preLoads)

# ObjectHashesDict = {}
# RecievedChunksDict = {}
# HOLsDict = {}
# ComputationsDict = {}
# PreloadsDict = {}
# ResourcesDict = {}

# copydict = lambda dct, keys: {key: dct[key] for key in keys}

# ObjectHashesDict = copydict(json_data, 'ObjectHash')
# RecievedChunksDict = copytdict(json_data, 'RecievedChunk')
# HOLsDict = copytdict(json_data, 'HOL')
# ComputationsDict = copytdict(json_data, 'Computation')
# PreloadsDict = copyDict(json_data, 'Preloads')
# ResourcesDict = copytdict(json_data, 'Resource')

# HOLsDict['Hol'].append[] # Append a value for each HOL making it easier to ID

# RecievedChunksDict['RecievedChunk'].append # Add ResourceID param to the  Recieved Chunks 