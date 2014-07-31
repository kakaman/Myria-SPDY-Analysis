
import json as j
datafile = open(r'C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro\ask.fm_-1378093801077-1', 'r')
json_data = [j.loads(line) for line in datafile]

json_data[]
for line in datafile:
	json_data.append(line)
	if json_data[]

print json_data

# Creates a new list for each line
resources = [line['Resource'] for line in json_data if line.get('Resource') is not None] # get DNE

# Equivalent code
resources = []
for line in json_data:
	if 'Resource' in line:
		resources.append(line)

# Adds the ResourceID column to the RecievedChunk data
rID = 0
recievedChunk = []
for line in json_data:
	if 'Resource' in line:
		rID = line.get('id') # get the resourceID
	if 'RecievedChunk' in line
		recievedChunk.append(line)
		recievedChunk.extend('ResourceID' : rID)

cID= 0
computation = []
for line in json_data:
	if line.get('Computation') is not None:
		computation.append(line['Computation'])
		computation.extend('ComputationID' : cID)
		cID++



ObjectHashesDict = {}
RecievedChunksDict = {}
HOLsDict = {}
ComputationsDict = {}
PreloadsDict = {}
ResourcesDict = {}

copydict = lambda dct, keys: {key: dct[key] for key in keys}

ObjectHashesDict = copydict(json_data, 'ObjectHash')
RecievedChunksDict = copytdict(json_data, 'RecievedChunk')
HOLsDict = copytdict(json_data, 'HOL')
ComputationsDict = copytdict(json_data, 'Computation')
PreloadsDict = copyDict(json_data, 'Preloads')
ResourcesDict = copytdict(json_data, 'Resource')

HOLsDict['Hol'].append[] # Append a value for each HOL making it easier to ID

RecievedChunksDict['RecievedChunk'].append # Add ResourceID param to the  Recieved Chunks 