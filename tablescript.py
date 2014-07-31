import json as j
datafile = open('C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro', 'r')
json_data = j.reader(datafile)
data = []
for row in json_data:
	data.append(row)


import json as j
datafile = open('C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro', 'r')
json_data = j.loads(datafile)

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



# Adding ResourceIDs to RecievedChunks
# do it when originally parsing
# i.e find the resource before it and add its id

rID = 0

for keys, values in json_data:
	if key == 'Resource':
		rID = json_data['Resource']['id']

	if key == 'RecievedChunk':
		json_data['RecievedChunk']['ResourceID'] = rID 