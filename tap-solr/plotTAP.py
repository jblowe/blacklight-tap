import solr
import sys
import csv, os, shutil
from pathlib import Path
from collections import defaultdict

core = sys.argv[1]
query = sys.argv[2]
rows = int(sys.argv[3])
base_dir = sys.argv[4]
delim = '\t'

FIELDS = 'SITE_s YEAR_s OP_s LOT_s AREA_s LEVEL_s MATERIAL_s NOTES_s SQ_s STRATUM_s CLASS_s ROLL_s EXP_s FILENAME_ss'.split(' ')
LOCATION_FIELDS = 'SITE_s YEAR_s OP_s LOT_s SQ_s AREA_s LEVEL_s'.split(' ')
ARTIFACT = 'MATERIAL_s NOTES_s FEA_s STRATUM_s CLASS_s ROLL_s EXP_s FILENAME_ss'.split(' ')

list_of_paths = defaultdict(int)
# create a connection to a solr server
s = solr.SolrConnection(f'http://localhost:8983/solr/{core}')

def move_file(filename, src_fpath, dest_fpath):
    os.makedirs(os.path.dirname(dest_fpath), exist_ok=True)
    shutil.copy(src_fpath, dest_fpath)
    # shutil.move(f'thumbnails/{filename}', f'projects/{project}/{filename}')

# do a search
response = s.query(query, rows=rows)
print(response.numFound)
for hit in response.results:

    try:
        result = {}
        for r in hit:
            path = ''
            for f in LOCATION_FIELDS:
                cell = hit.get(f)
                if cell is not None:
                    if type(cell) == type([]):
                        cell_str = cell[0]
                        result[f] = cell[0]
                    else:
                        cell_str = cell
                        result[f] = cell
                    path += '/' + cell_str
    except:
        raise
        result = {}

    list_of_paths[path] += 1
    # print(path)
    # filepath = Path('folder/subfolder/out.csv')
    filepath = Path(base_dir + path)
    #filepath.parent.mkdir(parents=True, exist_ok=True)

for p in sorted(list_of_paths):
    print(f'{list_of_paths[p]}\t{p}')

