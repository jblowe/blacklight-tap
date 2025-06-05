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

DOCS = 'SCHEMATIC SCANS SCAN PROFILES PROFILE REPORTS REPORT GRAPHS GRAPH SUMMARIES SUMMARY FORMS FORM NOTEBOOKS NOTEBOOK MAPS MAP SKETCHES SKETCH BURIAL BURIALS'.lower().split(' ')

title_labels = 't,site,year,roll,exp,op,sq,area,lot,fea,reg,bur,etc'.split(',')
extras = 'material,class,notes,description,date'.split(',')

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
        if label in 'site year'.split(' '):
            title = title + f'{row[n]} '
        else:
            if row[n] != '':
                title = title + f'{label.capitalize()[:2]}{row[n]} '

    for i, label in enumerate(extras):
        try:
            n = header.index(label.upper()+'_s')
        except:
            continue
        if row[n] not in title:
            title = title + f'{row[n]} '
    return title

def extract_terms(val):
    possible_string = val.replace('/Users/johnlowe/Box Sync/TAP Collaborations/', '')
    #possible_terms = re.split(r"[,\s;\/\._%\|\)\(\]\[]+", possible_string)
    possible_terms = re.split(r"[\W_]+", possible_string)
    keyterms = set()
    document_type = set()
    for p in possible_terms:
        if p == '': continue
        if p in 'johnlowe,Users,TAP,Box,Sync,Photos'.split(','):
            continue
        p = p.lower()
        p = re.sub(r'e?s$', '', p)
        if p in DOCS: document_type.add(p)
    [keyterms.add(x.lower()) for x in possible_terms]
    #print(possible_string,'\n',keyterms,'\n', DOC)
    return keyterms, document_type


header = []
with open(input_file) as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for i, row in enumerate(csvinput):
            keyterms, doc = extract_terms(' '.join(row))
            title_string = extract_title(row, header)
            keyterm_string = '|'.join([x for x in keyterms if x != ''])
            doc_string = '|'.join([x for x in doc if x != ''])
            if i == 0:
                title_string = 'TITLE_s'
                keyterm_string = 'KEYTERMS_ss'
                doc_string = 'DOC_ss'
                # rename TITLE_s if it already exists in incoming data
                try:
                    n = row.index('TITLE_s')
                    row[n] = 'TITLE2_s'
                except:
                    pass
                header = row
            csvoutput.writerow(row + [title_string, keyterm_string, doc_string])

