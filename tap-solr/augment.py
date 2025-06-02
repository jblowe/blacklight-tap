import solr
import sys
import csv, os, shutil

core = sys.argv[1]
query = sys.argv[2]
query += ':"{}"'
key_row = int(sys.argv[3])
input_file = sys.argv[4]
output_file = sys.argv[5]
rows = 10
delim = '\t'

FIELDS = 'SITE_s YEAR_s OP_s LOT_s AREA_s LEVEL_s MATERIAL_s NOTES_s SQ_s STRATUM_s CLASS_s ROLL_s EXP_s FILENAME_ss'.split(' ')

# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

# with csv.reader(open(input_file, 'r'), delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255)) as inputfile:
with open(input_file, 'r') as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for i, row in enumerate(csvinput):
            # handle header row
            if i == 0:
                row += 'TL TN LINK'.split(' ') + [f.replace('_s', '') for f in FIELDS]
                csvoutput.writerow(row)
                continue
            key = row[key_row]
            filled_in_query = query.format(key)
            response = s.query(filled_in_query, rows=rows)
            # print(response.numFound)
            # if response.numFound > 1:
                # print('multiple')
            try:
                result = {}
                for r in response.results:
                    for f in FIELDS:
                        cell = r.get(f)
                        if cell is not None:
                            if type(cell) == type([]):
                                result[f] = cell[0]
                            else:
                                result[f] = cell
            except:
                result = {}

            TL = row[2][5]
            TN = row[2][6:]
            row += [TL, TN]
            # https://54.185.36.2/?search_field=T_txt&q=3065
            hyperlink = f'=HYPERLINK("https://54.185.36.2/?search_field=T_txt&q={key}"; "link")'
            row.append(hyperlink)

            for f in FIELDS:
                row.append(result.get(f))
            csvoutput.writerow(row)
            # print(result)

