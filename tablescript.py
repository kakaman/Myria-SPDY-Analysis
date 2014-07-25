import json as j
datafile = open('C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro', 'r')
json_data = j.reader(datafile)
data = []
for row in json_data:
	data.append(row)

## Different method

import json as j
datafile = open('C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro', 'r')
json_data = j.JSONDecoder(datafile)

for row in json_data:
		if row[0] == 'Resource':

		elif row[0] == 'ObjectHash':
		
		elif row[0] == 'RecievedChunk':
		
		elif row[0] == 'HOL':
		
		elif row[0] == 'Computation':
		
		elif row[0] == 'Preloads': # or use else:
