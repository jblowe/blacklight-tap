import solr
import sys
from collections import defaultdict
import csv
import re
from image_fn import parse_image_filename, extract_fields

input_file = sys.argv[1]
output_file = sys.argv[2]
rows = 100000
delim = '\t'

# nb: DTYPE_s is handled specially further down
OUTPUT_FIELDS = 'DTYPE_s SITE_s YEAR_s OP_s LOT_s REG_s AREA_s LEVEL_s MATERIAL_s NOTES_s TRAY_s SQ_s STRATUM_s CLASS_s BUR_s ROLL_s EXP_s T_s IMAGENAME_s FILENAME_s DOC_s'.split(' ')
FIELDS = defaultdict(int)
SEQ = 0

TERMS = {
    'PREFIX': 'TAP'.split(' '),
    'SITE': 'NKH NPW NML TK'.split(' '),
    'OP': 'OP'.split(' '),
    'SQ': 'SQUARE SQ'.split(' '),
    'LOT': 'LOT AREA AERA'.split(' '),
    'REG': 'REG'.split(' '),
    'FEA': 'FEA FEAT FEATURE'.split(' '),
    'BUR': 'BURIALS BURIAL BUR B'.split(' '),
    'ROLL': 'ROLL ROL R'.split(' '),
    'T': 'T# T'.split(' '),
    'EXP': '#'
}


DOCS = 'SCHEMATIC SCAN PROFILE REPORT GRAPH SUMMAR FORMS FORM NOTEBOOK MAP SKETCH'.lower().split(' ')


def extract_terms(val):
    imagename, filename = parse_image_filename(val)
    (dtype, site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, etc) = extract_fields(imagename, val)
    relative_path = val.replace('/Users/johnlowe/Box Sync/TAP Collaborations/', '')
    path_elements = re.split(r'\b',relative_path.replace('/',' ').replace('_',' '))
    filename = path_elements[-1]
    keyterms = set()
    fields = defaultdict()
    for p in path_elements:
        if p == '': continue
        for d in DOCS:
            if d in p.lower():
                fields['DOC'] = d
                p = re.sub(d + ' +?', '', p, flags=re.IGNORECASE)
        for t in TERMS:
            for k in TERMS[t]:
                if k == p.upper():
                    fields[t] = k
                    continue
                regx = f'({k})[ _\\-]?(\\d+|[A-Z])\\b'
                terms = re.search(regx, p, re.IGNORECASE)
                if terms is not None:
                    if t == 'PREFIX':
                        try:
                            int(terms[2])
                            fields['YEAR'] = terms[2]
                        except:
                            pass
                    elif t == 'SITE':
                        try:
                            int(terms[2])
                            fields['YEAR'] = terms[2]
                            fields[t] = terms[1]
                        except:
                            pass
                    else:
                        fields[t] = terms[2]
                    keyterms.add(f'{k} {terms[2]}')
                    p = p.replace(f'{terms[0]}', '')
    k2 = re.findall(r'\w+', relative_path.replace('_', ' '))
    extras = set()
    [extras.add(x) for x in k2 if x not in keyterms]
    for INT in 'ROLL EXP BUR YEAR LOT SQ REQ OP'.split(' '):
        if INT in fields:
            try:
                fields[INT] = str(int(fields[INT]))
            except:
                if fields[INT] in 'tsryahe':
                    del fields[INT]
    return keyterms, extras, fields, filename, 'box/' + relative_path


path_col = 0
with open(input_file) as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        csvoutput.writerow(OUTPUT_FIELDS)
        for i, row in enumerate(csvinput):
            keyterms, extras, fields, filename, boxpath = extract_terms(row[path_col])
            # fields['KEYTERMS'] = '|'.join([ x for x in extras])
            fields['DTYPE'] = 'box'
            fields['FILENAME'] = boxpath
            fields['IMAGENAME'] = filename
            output_record = [fields.get(o.replace('_s', ''), '') for o in OUTPUT_FIELDS]
            csvoutput.writerow(output_record)
