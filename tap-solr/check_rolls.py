import solr
import sys
from collections import defaultdict
import csv

core = 'tap'
query = 'SITE_s:"{}" AND YEAR_s: {}'
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
SEQ = 0
OUTPUT_COUNT = 0
MERGED_COUNT = 0


def get_cell(hit, key):
    cell = hit.get(key, '')
    if type(cell) == type([]):
        return cell[0]
    else:
        return cell


errors = defaultdict(int)
def write_errors(message, flds):
    csverrors.writerow([message] + flds)
    errors[message] += 1


errorfile = open('merge_errors.csv', 'w')
csverrors = csv.writer(errorfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

for i, site in enumerate(LOCATIONS):
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
        for counter, hit in enumerate(list(response.results)):
            if year in YEARS and site in LOCATIONS:
                DIST[year][site] += 1
            else:
                write_errors('site or season not found', [site, year])

exit(0)

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
    header = 'SITE_S YEAR_s ROLL_s EXP_s'.split(' ')
    csvoutput.writerow(header)
    # generate merged records as csv fields
    for key in keys:
        subrecord = []
        title = ''
        merged_records = defaultdict(list)
        merged_fields = len(OUTPUT_FIELDS) * ['']
        for r in keys[key]:
            for i, f in enumerate(OUTPUT_FIELDS):
                if merged_fields[i] == '':
                    merged_fields[i] = get_cell(r[4], f)
            output_arr = []
            if 'TITLE_s' in r[4]:
                incoming_title = get_cell(r[4], 'TITLE_s')
                if len(incoming_title) > len(title):
                    title = incoming_title
            [output_arr.append(get_cell(r[4], f)) for f in ['DTYPE_s'] + OUTPUT_FIELDS]
            output_str = '%'.join(output_arr)
            if output_str in subrecord:
                write_errors('duplicate record in set', [[key] + output_arr])
            subrecord.append(output_str)
            add_items(merged_records, r[4])
            OUTPUT_COUNT += 1

        record_count = sum([merged_records['DTYPES_ss'][d] for d in merged_records['DTYPES_ss']])
        if record_count > 100:
            write_errors('pathological merged record', [key, title, merged_records['DTYPES_ss']])
            continue

        output_record = [key, 'merged records', title,
                         format_dtypes(merged_records['DTYPES_ss']),
                         format_dtypes_only(merged_records['DTYPES_ss']),
                         '|'.join(subrecord),
                         '|'.join(merged_records['IMAGES']),
                         '|'.join(merged_records['FILENAMES'])
                         ] + merged_fields
        csvoutput.writerow(output_record)
        MERGED_COUNT += 1

print(f'input records, {SEQ}')
print(f'output records, {OUTPUT_COUNT}')
print(f'merged records, {MERGED_COUNT}')

print('\nType & Token counts\n')
for f in sorted(FIELDS):
    print(f'{f}\t{FIELDS[f]}')

print('\nKey type counts\n')
for k in sorted(KEY_TYPES):
    print(f'{k}\t{KEY_TYPES[k]}')

print('\ndocument type counts\n')
for d in sorted(DTYPE_COUNTS):
    print(f'{d}\t{DTYPE_COUNTS[d]}')

print('\ndistribution\n')
# print(DIST)

# print('{:10}'.format(''),end='')
# for l in LOCATIONS:
#     print('{:10}'.format(l),end='')
# print()
# for s in YEARS:
#     print('{:10}'.format(s), end='')
#     for l in LOCATIONS:
#         print('{:10}'.format(DIST[s][l]),end='')
#     print()

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
