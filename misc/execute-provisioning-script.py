import json
from pprint import pprint

with open('test.json') as data_file:
    data = json.load(data_file)

pprint(data["SourceSystem"])
