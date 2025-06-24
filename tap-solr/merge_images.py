import solr
import sys
from collections import defaultdict
import csv
import re

core = 'tap'
query = 'DTYPE_s:"{}"'
total_records = 0
output_file = sys.argv[1]
rows = 100000
delim = '\t'

# nb: DTYPE_s is handled specially further down; THUMBNAIL and FILENAME eliminated -- redundant
OUTPUT_FIELDS = 'T_s SITE_s YEAR_s OP_s SQ_s LOT_s ROLL_s EXP_s AREA_s TRAY_s LEVEL_s MATERIAL_s NOTES_s STRATUM_s CLASS_s ' + \
                'IMAGENAME_s BURIAL_s COUNT_s DIRECTORY_s DTYPES_ONLY_ss DTYPES_ss DOC_ss ' + \
                'ENTRY_DATE_s ETC_s EXCAVATIONDATE_s EXCAVATOR_s FEATURE__s FEA_s ' + \
                'FILENAMES_ss IMAGES_ss KEYTERMS_ss ' + \
                'RECORDS_ss REGISTRAR_s REG_s SEASON_s ' + \
                'UNKNOWN_s WEIGHT_s'
OUTPUT_FIELDS = OUTPUT_FIELDS.split(' ')
FIELDS = defaultdict(int)
KEY_TYPES = defaultdict(int)
record_list = []
keys = defaultdict(list)
DTYPE_COUNTS = defaultdict(int)
DTYPES = 'master polaroids tray images photologs bags box'.split(' ')
# DTYPES = 'photologs images polaroids box'.split(' ')
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


def format_dtypes(dtypes):
    result = []
    [result.append(f'{d}: {dtypes[d]}') for d in dtypes]
    return '|'.join(result)


def format_dtypes_only(dtypes):
    result = []
    [result.append(f'{d}') for d in dtypes]
    return '|'.join(result)


def get_cell(hit, key):
    cell = hit.get(key, '')
    if type(cell) == type([]):
        return cell[0]
    else:
        return cell


def add_items(merged_records, hit):
    if hit is not None:
        # merged_records['RECORDS'].append(hit)
        if hit.get('THUMBNAIL_s') is not None: merged_records['IMAGES'].append(hit.get('THUMBNAIL_s'))
        if hit.get('FILEPATH_s') is not None: merged_records['FILENAMES'].append(hit.get('FILEPATH_s'))
        this_dtype = get_cell(hit, 'DTYPE_s')
        if 'DTYPES_ss' not in merged_records:
            merged_records['DTYPES_ss'] = defaultdict(int)
        merged_records['DTYPES_ss'][this_dtype] += 1
        DTYPE_COUNTS[this_dtype] += 1


# special cases
def fix_hit(hit):
    if 'YEAR_s' in hit and hit['YEAR_s'] == '8':
        hit['YEAR_s'] = '86'
    if 'YEAR_s' in hit and hit['YEAR_s'] == '86' and 'T_s' in hit and 'T_s' == '1':
        hit['T_s'] = ''


def compute_pattern(filename):
    pass

errors = defaultdict(int)
def write_errors(message, flds):
    csverrors.writerow([message] + flds)
    errors[message] += 1


errorfile = open('merge_errors.csv', 'w')
csverrors = csv.writer(errorfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

for i, dtype in enumerate(DTYPES):
    filled_in_query = query.format(dtype)
    # do a search for each document type
    response = s.query(filled_in_query, rows=rows)

    # x = list(response.results)
    print(dtype, response.numFound)
    total_records += response.numFound
    for counter, hit in enumerate(list(response.results)):
        key_type = dtype
        key_tno = ''
        key_photo = ''
        SEQ += 1
        key_seq = f'S{SEQ:05}'
        fix_hit(hit)
        for r in hit:
            if '_s' in r:
                FIELDS[r] += 1
        if 'Site_s' in hit and hit['SITE_s'] == 'isotope':
            record_list.append(['',f'isotope {hit["ETC_s"]}','', 'isotope', hit])
            KEY_TYPES['isotope date'] += 1
            continue
        if 'T_s' in hit:
            if hit['T_s'] != 'no T#':
                try:
                    key_tno = str(int(hit['T_s']))
                    # tno_key = tno_key if 'T' not in tno_key else f'T{tno_key}'
                    hit['T_s'] = f'{key_tno}' if 'T' == key_tno[0] else f'T{key_tno}'
                    KEY_TYPES[dtype + ' Tno'] += 1
                except:
                    write_errors('non-numeric T#', [hit['T_s']])
                    key_tno = hit['T_s']
            else:
                key_tno = ''
        SEASON = hit.get('SEASON_s', 'SS')
        YEAR = hit.get('YEAR_s', 'YY')
        ROLL = hit.get('ROLL_s', 'RRR')
        EXP = hit.get('EXP_s', 'EEE')
        SITE = hit.get('SITE_s', 'SSS')
        DIRECTION = hit.get('DIRECTION_s', 'DDD')
        SKETCH = hit.get('SKETCH_s', 'KKK')
        FILEPATH = hit.get('FILEPATH_s', 'not a file')
        OP = hit.get('OP_s', '')
        SQ = hit.get('SQ_s', '')
        BU = hit.get('BURIAL_s', '')
        if key_tno == '':
            if SITE not in 'NPW|NKH|NML|PL|KTK'.split('|'):
                try:
                    SITE = SEASONS[YEAR]
                except:
                    SITE = 'SSS'
                    YEAR = 'YY'
            try:
                check = int(EXP)
            except:
                EXP = 'EEE'
            if DIRECTION != 'DDD' or SKETCH != 'KKK':
                key_photo = f"{SITE.ljust(3)} {YEAR} {OP} {DIRECTION} {SKETCH}".replace('  ',' ').replace('  ',' ')
                KEY_TYPES[dtype + ' OP DDD KKK'] += 1
            elif ROLL != 'RRR' and EXP != 'EEE':
                if SEASON =='92':
                    key_photo = f"{SITE} {SEASON} {ROLL.zfill(3)} {EXP.zfill(3)}"
                    KEY_TYPES[dtype + ' SSS SS R E'] += 1
                else:
                    key_photo = f"{SITE} {ROLL.zfill(3)} {EXP.zfill(3)}"
                    KEY_TYPES[dtype + ' SS R E'] += 1
                # photo_key = f"{YEAR} {ROLL.zfill(3)} {EXP.zfill(3)}"
            elif (OP + SQ + BU) != '':
                key_photo = f"{SITE.ljust(3)} {SEASON} {OP} {SQ} {BU}".replace('  ',' ').replace('  ',' ')
                KEY_TYPES[dtype + ' SSS YY OP/SQ BU'] += 1
            elif ROLL != 'RRR' or EXP != 'EEE':
                key_photo = f"{SITE.ljust(3)} {YEAR} {ROLL.zfill(3)} {EXP.zfill(3)}"
                KEY_TYPES[dtype + ' SSS YY R E'] += 1
            else:
                key_seq = ''
                KEY_TYPES[dtype + ' SEQ'] += 1

        if 'T# 15141 TAP 92 Op1 Burial 2' in hit.get('FILENAME_s',''):
            pass

        record_list.append([key_tno, key_photo, key_seq, dtype, hit])
        if [key_tno, key_photo, key_seq] == [''] * 3:
            write_errors('empty keys', [hit[h] for h in OUTPUT_FIELDS if '_s' in h and h in hit and 'KEYTERMS' not in h])
        if (SITE == 'SSS' or YEAR == 'YY') and key_tno == '':
            write_errors(f'vague key', [dtype, key_tno, key_photo, key_seq, FILEPATH])
        if YEAR in YEARS and SITE in LOCATIONS:
            DIST[YEAR][SITE] += 1
        else:
            write_errors('site or season not found', [SITE, YEAR])
        if 'FILENAME_s' in hit and 'TAP 92 NPW OP7 B1' in hit['FILENAME_s']:
            pass

# consolidate records on keys
for r in record_list:
    if r[0] != '':
        keys[r[0]].append(r)
    elif r[1] != '':
        keys[r[1]].append(r)
    elif r[2] != '':
        keys[r[2]].append(r)
    else:
        write_errors('no key generated', [r[4][h] for h in OUTPUT_FIELDS if '_s' in h and h in r[4] and 'KEYTERMS' not in h])

with open(output_file, 'w') as outputfile:
    csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_MINIMAL)
    FIELD_LIST = sorted(FIELDS)
    header = 'id KEY_s DTYPE_s TITLE_s DTYPES_ss DTYPES_ONLY_ss RECORDS_ss IMAGES_ss FILENAMES_ss'.split(' ')
    csvoutput.writerow(header + OUTPUT_FIELDS)
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

        if key == 'SS 010 010':
            pass

        output_record = [re.sub(r'[_\W]+','_',title), key, 'merged records', title,
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
