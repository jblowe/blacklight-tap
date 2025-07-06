import solr
import sys
from collections import defaultdict
import csv
import re
from image_fn import parse_image_filename, extract_fields

input_file = sys.argv[1]
# parse input filename to get info for id
id_info = re.match(r'.*/TAP(\d+)?_(\w+)\.', input_file)
id_year = id_info[1] if id_info[1] is not None else ''
id_prefix = id_info[2]
output_file = sys.argv[2]
rows = 100000
delim = '\t'

DOCS = 'SCHEMATIC SCANS SCAN PROFILES PROFILE REPORTS REPORT GRAPHS GRAPH SUMMARIES SUMMARY FORMS FORM NOTEBOOKS NOTEBOOK MAPS MAP SKETCHES SKETCH BURIAL BURIALS'.lower().split(' ')

title_labels = 't,site,season,year,roll,exp,op,sq,area,lot,fea,reg,direction,sketch,burial'.split(',')
extras = 'direction,profile,map,etc,material,class,notes,description,date'.split(',')

def get_index(lst,fld):
    pass

def extract_title(row, header):
    title = ''
    etc = ''
    for i, label in enumerate(title_labels):
        try:
            n = header.index(label.upper()+'_s')
        except:
            continue
        if label in 'site year season t'.split(' '):
            title = title + f'{row[n].upper()} '
        else:
            if row[n] != '':
                title = title + f'{label.capitalize()[:2]}{row[n].upper()} '

    for i, label in enumerate(extras):
        try:
            n = header.index(label.upper()+'_s')
        except:
            continue
        if row[n] not in title:
            title = title + f'{row[n]} '
    return title.replace('/','_').replace('#','_').replace('__','_').strip()

def extract_terms(val):
    possible_string = val.replace('/Users/johnlowe/Box Sync/TAP Collaborations/', '')
    possible_terms = re.split(r"[\W_]+", possible_string.lower())
    keyterms = set()
    document_types = set()
    for p in possible_terms:
        if p == '': continue
        if p in 'johnlowe,users,tag,box,sync'.split(','):
            continue
        p = re.sub(r'e?s$', '', p)
        if p in DOCS: document_types.add(p)
    if ('burial' in val.lower() or re.search(r' Bu\d+', val) is not None) and 'burial' not in document_types:
        document_types.add('burial')
    [keyterms.add(x.lower()) for x in possible_terms]
    #print(possible_string,'\n',keyterms,'\n', DOC)
    return keyterms, document_types


header = []
with open(input_file) as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for row_count, row in enumerate(csvinput):
            keyterms, doc = extract_terms(' '.join(row))
            title_string = extract_title(row, header)
            keyterm_string = '|'.join([x for x in keyterms if x != ''])
            doc_string = '|'.join([x for x in doc if x != ''])
            if row_count == 0:
                try:
                    dtype_column= row.index('DTYPE_s')
                except:
                    print('DTYPE undetected', row)
                # add an id column if there isn't one
                if row[0] == 'id':
                    has_id = True
                else:
                    has_id = False
                title_string = 'TITLE_s'
                keyterm_string = 'KEYTERMS_ss'
                doc_string = 'DOC_ss'
                # rename TITLE_s if it already exists in incoming data
                for n, r in enumerate(row):
                    if r == 'TITLE_s':
                        row[n] = 'TITLE_ss'
                # rename DOC_ss if it already exists in incoming data
                try:
                    n = row.index('DOC_ss')
                    row[n] = 'DOC2_ss'
                except:
                    pass
                header = row
                id = 'id'
            else:
                # if we are processing the merged file, use its ids
                if id_prefix in ['merged']:
                    # id = re.sub(r'[_\W]+','_',title_string)
                    id = row[0]
                else:
                    id = id_prefix + id_year + str(row_count)
            if has_id:
                row[0] = id
            else:
                row = [id] + row
            csvoutput.writerow(row + [title_string, keyterm_string, doc_string])

