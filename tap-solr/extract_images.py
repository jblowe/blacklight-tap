import solr
import sys
import csv
import requests

core = 'tap'
output_file = sys.argv[1]
total_records = 0
delim = '\t'

ROLL_COUNT = 0
MISSING_COUNT = 0
IMAGE_COUNT = 0

solr_url = "http://localhost:8983/solr/tap/select"
# create a connection to a solr server
# s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
    #header = 'Season Roll# Status CommonCount MissingCount ImageOnlyCount PhotologOnlyCount Missing ImageOnly PhotoLogOnly'.split(' ')
    fields = 'id,T_s,ROLL_s,EXP_s,OP_s,SQ_s,AREA_s,LOT_s,FEA_s,REG_s,BURIAL_s,DIRECTION_s,SKETCH_s,MAPS_s,ETC_s,SITE_s,SEASON_s,REVISED_FILENAME_s,TITLE_s'
    csvoutput.writerow(['image'] +fields.split(','))

    params = {
        "q": "*:*",
        "rows": 1000,  # batch size
        "sort": "id asc",  # must sort on a uniqueKey field
        "cursorMark": "*",
        # "fl": "id,other_fields",  # list fields you want to retrieve
        "wt": "json"
    }

    done = False
    while not done:
        response = requests.get(solr_url, params=params)
        data = response.json()
        docs = data['response']['docs']
        for doc in docs:
            # print(doc)  # or save/process it
            if 'IMAGES_ss' not in doc: continue
            for image in doc['IMAGES_ss']:
                ROLL_COUNT += 1
                output_record = [image]
                for column in fields.split(','):
                    if column in doc:
                        output_record.append(doc[column])
                    else:
                        output_record.append('')
                csvoutput.writerow(output_record)

        next_cursor = data.get('nextCursorMark')
        if next_cursor == params['cursorMark']:
            done = True
        else:
            params['cursorMark'] = next_cursor


print(f'rolls, {ROLL_COUNT}')
print(f'images, {IMAGE_COUNT}')
