import solr
import sys
from collections import defaultdict
from sortedcontainers import SortedSet
import csv

core = 'tap'
output_file = sys.argv[1]
total_records = 0
rows = 100000
facet_limit = 100000
delim = '\t'

# nb: DTYPE_s is handled specially further down; THUMBNAIL and FILENAME eliminated -- redundant
OUTPUT_FIELDS = 'SITE_s YEAR_s ROLL_s EXP_s T_s OP_s SQ_s'.split(' ')
record_list = []
OP_DIST = {}
BURIAL_DIST = {}
SEASONS = '86 90 92 93 94 YY'.split(' ')
LOCATIONS = 'NPW|NKH|NML|PL|KTK|BKPK'.split('|')
#for s in SEASONS:
#   DIST[s] = 0
OP_COUNT = 0
MISSING_COUNT = 0
IMAGE_COUNT = 0

errors = defaultdict(int)

def convert_to_int(val):
    if val is None:
        return ''
    try:
        x = int(val)
        return x
    except:

        return val

# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)

    all_ops = defaultdict(int)

    for count, site in enumerate(LOCATIONS):
        filled_in_query = f'SITE_s: "{site}"'
        # do a search for each document type
        response = s.query(filled_in_query, facet='true', facet_field='ROLL_s,EXP_s,OP_s,BURIAL_s'.split(','),
                           fq={},
                           fields='ROLL_s,EXP_s,OP_s,SQ_s,BURIAL_s,SITE_s'.split(','),
                           rows=0, facet_limit=facet_limit,
                           facet_mincount=1)

        facets = response.facet_counts['facet_fields']

        x = list(response.results)
        print(site, response.numFound)
        OPS = facets['OP_s']
        OP_DIST[site] = facets['OP_s']
        combined = {k: all_ops.get(k, 0) + facets['OP_s'].get(k, 0) for k in set(all_ops) | set(facets['OP_s'])}
        all_ops = combined

    op_keys = [o for o in all_ops if all_ops[o] > 10]
    csvoutput.writerow(['site'] + sorted(op_keys))

    for site in sorted(OP_DIST):
        ops = []
        for op in sorted(op_keys):
            if op in OP_DIST[site]:
                ops.append(OP_DIST[site][op])
            else:
                ops.append(0)
        csvoutput.writerow([site] +  ops)

print(f'OPs, {OP_COUNT}')
print('expected at least', OP_COUNT * 36, 'images @ 36 per OP')
print(f'missing image or log, {MISSING_COUNT}')
print(f'images, {IMAGE_COUNT}')

#for s in SEASONS:
#    print(f'{s}\t{DIST[s]}')
print()

for e in errors:
    print(f'{e}: {errors[e]}')

print()
