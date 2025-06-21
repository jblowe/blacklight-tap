import solr
import sys
from collections import defaultdict
import csv

core = 'tap'
query = 'DTYPE_s:"images" AND SITE_s:"{}" AND YEAR_s: {}'
total_records = 0
output_file = sys.argv[1]
rows = 100000
facet_limit = 100000
delim = '\t'

# nb: DTYPE_s is handled specially further down; THUMBNAIL and FILENAME eliminated -- redundant
OUTPUT_FIELDS = 'SITE_s YEAR_s ROLL_s EXP_s T_s OP_s SQ_s'.split(' ')
record_list = []
keys = defaultdict(list)
SEASONS = {'86': 'NPW', '90': 'NKH', '92': 'NKH', '94': 'NML'}
DIST = defaultdict(defaultdict)
YEARS = '86 90 92 93 94 YY'.split(' ')
LOCATIONS = 'NPW|NKH|NML|PL|KTK|BKPK|SSS'.split('|')
for s in YEARS:
    for l in LOCATIONS:
        DIST[s][l] = 0
ROLL_COUNT = 0
MISSING_COUNT = 0
IMAGE_COUNT = 0

errors = defaultdict(int)
def write_errors(message, flds):
    csverrors.writerow([message] + flds)
    errors[message] += 1


errorfile = open('photo_errors.csv', 'w')
csverrors = csv.writer(errorfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
    header = 'SITE_S YEAR_s ROLL_s EXP_s'.split(' ')
    csvoutput.writerow(header)

    for count, site in enumerate(LOCATIONS):
        for year in YEARS:
            filled_in_query = query.format(site, year)
            # do a search for each document type
            response = s.query(filled_in_query, facet='true', facet_field='ROLL_s,EXP_s,OP_s,BURIAL_s'.split(','),
                               fq={},
                               fields='ROLL_s,EXP_s,OP_s,BURIAL_s'.split(','),
                               rows=rows, facet_limit=facet_limit,
                               facet_mincount=1)

            facets = response.facet_counts['facet_fields']

            x = list(response.results)
            print(site, year, response.numFound)
            total_records += response.numFound
            rolls = facets['ROLL_s']
            zz = sorted(rolls)
            ROLL_COUNT += len(rolls)
            for counter, roll in enumerate(zz):
                DIST[year][site] += 1
                roll_response = s.query(filled_in_query + f' AND ROLL_s:"{roll}"',
                                        fields='ROLL_s,EXP_s,OP_s,BURIAL_s'.split(','), rows=rows)
                exposure_list = set()
                for e in roll_response.results:
                    #print(e)
                    try:
                        exposure_list.add(int(e['EXP_s']))
                    except:
                        if 'EXP_s' in e:
                            print(f'exposure is not a number: {e["EXP_s"]}')
                        else:
                            print(f'no exposure associated with the record {e}')
                    pass
                for i in range(1,36):
                    if i in exposure_list:
                        IMAGE_COUNT += 1
                    else:
                        csvoutput.writerow(['missing', site, year, roll, str(i)])
                        # print(f'missing: {site} {year} {roll} {i}')
                        MISSING_COUNT += 1
                for i in range(37,40):
                    if i in exposure_list:
                        IMAGE_COUNT += 1
                        # print(f'extra: {site} {year} {roll} {i}')
                pass



print(f'rolls, {ROLL_COUNT}')
print('expected at least ', ROLL_COUNT * 36, 'images @ 36 per roll')
print(f'missing, {MISSING_COUNT}')
print(f'images, {IMAGE_COUNT}')

print('\t', end='')
for l in LOCATIONS:
    print(f'{l}\t', end='')
print()
for s in YEARS:
    print(f'{s}\t', end='')
    for l in LOCATIONS:
        print(f'{DIST[s][l]}\t', end='')
    print()

print()
for s in DIST:
    for l in DIST[s]:
        if l in LOCATIONS and s in YEARS:
            continue
        else:
            print(f'{s} {l} {DIST[s][l]}')

for e in errors:
    print(f'{e}: {errors[e]}')

print()
