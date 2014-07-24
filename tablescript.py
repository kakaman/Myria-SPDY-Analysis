import json as j
datafile = open('C:\Users\Vyshnav\Documents\GitHub\Myria-SPDY-Analysis\data\wprof_300_5_pro', 'r')
json_data = j.reader(datafile)
data = []
for row in json_data:
	data.append(row)

