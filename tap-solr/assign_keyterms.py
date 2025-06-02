import solr
import sys
from collections import defaultdict
import csv
import re

input_file = sys.argv[1]
output_file = sys.argv[2]
rows = 100000
delim = '\t'

DOCS = 'SCHEMATIC SCANS SCAN PROFILES PROFILE REPORTS REPORT GRAPHS GRAPH SUMMARIES SUMMARY FORMS FORM NOTEBOOKS NOTEBOOK MAPS MAP SKETCHES SKETCH'.lower().split(' ')

def extract_terms(val):
    possible_string = val.replace('/Users/johnlowe/Box Sync/TAP Collaborations/', '')
    #possible_terms = re.split(r"[,\s;\/\._%\|\)\(\]\[]+", possible_string)
    possible_terms = re.split(r"[\W_]+", possible_string)
    keyterms = set()
    DOC = set()
    for p in possible_terms:
        if p == '': continue
        if p in 'johnlowe,Users,TAP,Box,Sync,Photos'.split(','):
            continue
        p = p.lower()
        p = re.sub(r'e?s$', '', p)
        if p in DOCS: DOC.add(p)
    [keyterms.add(x.lower()) for x in possible_terms]
    #print(possible_string,'\n',keyterms,'\n', DOC)
    return keyterms, DOC


with open(input_file) as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for i, row in enumerate(csvinput):
            keyterms,doc = extract_terms(' '.join(row))
            keyterm_string = '|'.join([x for x in keyterms])
            doc_string = '|'.join([x for x in doc])
            if i == 0:
                keyterm_string = 'KEYTERMS_ss'
                doc_string = 'DOC_ss'
            csvoutput.writerow(row + [keyterm_string, doc_string])

