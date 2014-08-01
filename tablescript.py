
import json as j
import sys

datafile = open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro\ask.fm_-1378093801077-1', 'r')
json_data = [j.loads(line) for line in datafile]

print json_data[:5]

# Creates a new list for each line
resources = [line['Resource'] for line in json_data if line.get('Resource') is not None]

# # Equivalent code
# resources = []
# for line in json_data:
# 	if 'Resource' in line:
# 		resources.append(line)

# # Adds the ResourceID column to the RecievedChunk data
rID = None
receivedChunk = []
for line in json_data:
	if 'Resource' in line:
		rID = line['Resource']['id']
	elif 'ReceivedChunk' in line:
		assert rID is not None
		rc = line['ReceivedChunk']
		rc['ResourceID'] = rID
		receivedChunk.append(rc)
		print rc


cID = 0
computation = []
for line in json_data:
	if 'Computation' in line:
		comp = line['Computation']
		comp['ComputationID'] = cID
		computation.append(comp)
		cID = cID + 1
		print comp

holID = 0
hol = []
for line in json_data:
	if 'HOL' in line:
		temp = line['HOL']
		temp['holID'] = holID
		hol.append(temp)
		holID += 1

preLoads = [line['Preload'] for line in json_data if line.get('Preload') is not None]


import csv

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\preloads.csv', 'wb') as preLoadFile:
	w = csv.DictWriter(preLoadFile, preLoads[0].keys())
	w.writeheader()	
	for row in preLoads:
		w.writerow(row)


with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\computations.csv', 'wb') as preLoadFile:
	w = csv.DictWriter(preLoadFile, preLoads[0].keys())
	w.writeheader()	
	for row in preLoads:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\received.csv', 'wb') as preLoadFile:
	w = csv.DictWriter(preLoadFile, preLoads[0].keys())
	w.writeheader()	
	for row in preLoads:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\resources.csv', 'wb') as preLoadFile:
	w = csv.DictWriter(preLoadFile, preLoads[0].keys())
	w.writeheader()	
	for row in preLoads:
		w.writerow(row)

with open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\tables\hol.csv', 'wb') as preLoadFile:
	w = csv.DictWriter(preLoadFile, preLoads[0].keys())
	w.writeheader()	
	for row in preLoads:
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