import solr
import sys
from collections import defaultdict
import csv

core = 'tap'
output_file = sys.argv[1]
scope = sys.argv[2]
total_records = 0
rows = 100000
facet_limit = 100000
delim = '\t'

# nb: DTYPE_s is handled specially further down; THUMBNAIL and FILENAME eliminated -- redundant
OUTPUT_FIELDS = 'SITE_s YEAR_s ROLL_s EXP_s T_s OP_s SQ_s LOT_s FEA_s BURIAL_s KEY_s IMAGE_ss'.split(' ')
record_list = []
DIST = defaultdict(defaultdict)
SEASONS = '86 90 92 93 94 YY'.split(' ')
LOCATIONS = 'NPW|NKH|NML'.split('|')
#for s in SEASONS:
#   DIST[s] = 0
IMAGE_COUNT = 0

errors = defaultdict(int)

# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
    # csvoutput.writerow(OUTPUT_FIELDS)

    for count, location in enumerate(LOCATIONS):
        filled_in_query = f'SITE_s: "{location}" AND DTYPE_s: "images"'
        if scope == 'burials':
            filled_in_query += ' AND (KEYTERMS_ss:"burial" OR KEYTERMS_ss:"burials" OR BURIAL_s:*)'
        # do a search for each document type
        response = s.query(filled_in_query, facet='true', facet_field=OUTPUT_FIELDS,
                           fq={},
                           fields='SITE_s,OP_s,SQ_s,BURIAL_s'.split(','),
                           rows=0, facet_limit=facet_limit,
                           facet_mincount=1)

        facets = response.facet_counts['facet_fields']

        candidates = list(response.results)
        print(location, response.numFound)
        OPS = set(facets['OP_s'])
        SQS = set(facets['SQ_s'])
        BOTH = OPS | SQS
        for counter, op in enumerate(sorted(BOTH)):
            filled_in_query = f'SITE_s:"{location}" AND (OP_s: "{op}" OR SQ_s: "{op}") AND DTYPE_s: "merged records"'
            if scope == 'burials':
                filled_in_query += ' AND (KEYTERMS_ss:"burial" OR KEYTERMS_ss:"burials" OR BURIAL_s:*)'
                # filled_in_query += ' AND BURIAL_s:*'
            #op_response = s.query(filled_in_query, fields='SEASON_s,BURIAL_s,FEA_s,IMAGE_s'.split(','), rows=rows)
            op_response = s.query(filled_in_query, rows=rows)
            if op == 'A' and location == 'NPW':
                pass
            for o in op_response.results:
                IMAGES = o.get('IMAGES_ss',[])
                Tno = o.get('T_s', '')
                burials = o.get('BURIAL_s', 'xx')
                burials = burials.split('-')[0]
                burials = burials.split(',')
                for burial in burials:
                    burial = burial.zfill(2)
                    for image in IMAGES:
                        image = image.replace('/images/', '')
                        pass
                        csvoutput.writerow([f'{location}_Op{op}_B{burial}', location, op, burial, image, o.get('TITLE_ss')[0]])
                        IMAGE_COUNT += 1

print(f'images, {IMAGE_COUNT}')
