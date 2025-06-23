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
DIST = defaultdict(defaultdict)
SEASONS = '86 90 92 93 94 YY'.split(' ')
LOCATIONS = 'NPW|NKH|NML|PL|KTK|BKPK|SSS'.split('|')
#for s in SEASONS:
#   DIST[s] = 0
ROLL_COUNT = 0
MISSING_COUNT = 0
IMAGE_COUNT = 0

errors = defaultdict(int)


def write_errors(message, flds):
    csverrors.writerow([message] + flds)
    errors[message] += 1


def convert_to_int(val):
    if val is None:
        return ''
    try:
        x = int(val)
        return x
    except:

        return val


errorfile = open('images_errors.csv', 'w')
csverrors = csv.writer(errorfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
    header = 'Season Roll# Status CommonCount MissingCount ImageOnlyCount PhotologOnlyCount Missing ImageOnly PhotoLogOnly'.split(' ')
    csvoutput.writerow(header)

    for count, season in enumerate(SEASONS):
        filled_in_query = f'SEASON_s: "{season}"'
        # do a search for each document type
        response = s.query(filled_in_query, facet='true', facet_field='ROLL_s,EXP_s,OP_s,BURIAL_s'.split(','),
                           fq={},
                           fields='ROLL_s,EXP_s,OP_s,BURIAL_s, SITE_s'.split(','),
                           rows=0, facet_limit=facet_limit,
                           facet_mincount=1)

        facets = response.facet_counts['facet_fields']

        x = list(response.results)
        print(season, response.numFound)
        ROLLS = facets['ROLL_s']
        exposure_list = {}
        for counter, roll in enumerate(sorted(ROLLS)):
            for DTYPE in 'images photologs'.split(' '):
                filled_in_query = f'DTYPE_s:"{DTYPE}" AND SEASON_s: "{season}"'
                roll_response = s.query(filled_in_query + f' AND ROLL_s:"{roll}"', fields='ROLL_s,EXP_s,OP_s,BURIAL_s'.split(','), rows=rows)
                int_only = SortedSet()
                for e in roll_response.results:
                    try:
                        int_only.add(int(e['EXP_s']))
                    except:
                        if 'EXP_s' in e:
                            write_errors('exposure is not a number', [season, e['ROLL_s'],e['EXP_s']])
                        else:
                            # print(f'no exposure associated with the record {e}')
                            pass
                # print('counter', counter, 'roll', roll, [r.get('EXP_s') for r in roll_response.results if r.get('EXP_s') is not None])
                exposure_list[DTYPE] = int_only

            set_images = exposure_list['images']
            set_photologs = exposure_list['photologs']
            # Intersection
            common_exposures = set_images & set_photologs
            #print("matching exposures:", common_exposures)

            # images without photolog
            images_only = set_images - set_photologs
            #print("images without photolog:", images_only)

            # photolog without images
            photolog_only = set_photologs - set_images
            #print("photolog without images:", photolog_only)

            full_set = SortedSet([i for i in range(1,38)])
            missing_images = full_set - common_exposures
            # if there isn't a 37th image, ignore any associated photolog
            if 37 not in set_images and 37 in missing_images:
                missing_images.remove(37)
                # write_errors('no 37th image, but photolog exists', [season, roll])
            if len(missing_images) == 0 and len(common_exposures) != 0:
                status = 'OK'
            else:
                status = ''
            if len(common_exposures) == 0 and (len(set_photologs) != 0 or len(set_images) != 0):
                write_errors('roll with no common exposures', [season, roll, len(set_photologs), len(set_images)])
            # print(season, roll, images_only, missing_images)
            ROLL_COUNT += 1
            MISSING_COUNT += len(missing_images)
            IMAGE_COUNT += len(common_exposures)
            csvoutput.writerow([season, roll, status,
                                len(common_exposures),
                                len(images_only),
                                len(photolog_only),
                                len(missing_images),
                                ','.join([str(i) for i in images_only]),
                                ','.join([str(i) for i in photolog_only]),
                                ','.join([str(i) for i in missing_images]),
                               ])

print(f'rolls, {ROLL_COUNT}')
print('expected at least', ROLL_COUNT * 36, 'images @ 36 per roll')
print(f'missing image or log, {MISSING_COUNT}')
print(f'images, {IMAGE_COUNT}')

#for s in SEASONS:
#    print(f'{s}\t{DIST[s]}')
print()

for e in errors:
    print(f'{e}: {errors[e]}')

print()
