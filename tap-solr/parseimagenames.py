import re
import sys
from collections import defaultdict
import csv
from image_fn import parse_image_filename, extract_fields

delim = '\t'

input_file = sys.argv[1]
output_file = sys.argv[2]
with open(input_file, 'r') as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for i, row in enumerate(csvinput):

            # (tap_dir, tap_id, derivative, stat, filepath, pattern) = [''] * 6
            pattern = ''
            # (filename, pattern) = row
            (tap_dir, tap_id, derivative, stat, filepath) = row
            thumbnail = f'/images/{tap_dir}/{derivative}'
            thumbnail = thumbnail.replace('#', '_')
            imagename, filename = parse_image_filename(filepath)

            if i == 0:
                header = 'dtype_s t_s roll_s exp_s op_s sq_s area_s lot_s fea_s reg_s burial_s etc_s site_s year_s ' + \
                         'filename_s filepath_s thumbnail_s pattern_s directory_s'
                header = re.sub(r'_S', '_s', header.upper()).split(' ')
                csvoutput.writerow(header)

            (dtype, site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, etc) = extract_fields(imagename, filepath)

            output_record = [
                dtype, tno,
                roll, exp, op, sq, area, lot, fea, reg, bur, etc, site, season,
                filename, filepath, thumbnail, pattern, tap_dir
            ]
            csvoutput.writerow(output_record)
