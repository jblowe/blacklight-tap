import re
import sys
from collections import defaultdict
import csv
from image_fn import parse_image_filename, extract_fields

delim = '\t'

input_file = sys.argv[1]
output_file = sys.argv[2]
file_format = sys.argv[3]
with open(input_file, 'r') as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for i, row in enumerate(csvinput):

            pattern = ''
            if file_format == 'box':
                (tap_id, dummy, media_type, source, derivative, filename_only, filepath, stat, filesize) = [''] * 9
                filepath = f'Box/{row[0]}'
                thumbnail = ''
                filepath = filepath.replace('/Users/johnlowe/Box Sync/TAP Collaborations/', '')
            elif file_format == 'images':
                # (tap_dir, tap_id, derivative, stat, filepath) = row
                (tap_id, dummy, media_type, source, derivative, filename_only, filepath, stat, filesize) = row
                thumbnail = f'/images/{derivative}'
            imagename, filename = parse_image_filename(filepath)

            if i == 0:
                header = 'dtype_s t_s roll_s exp_s op_s sq_s area_s lot_s fea_s reg_s burial_s direction_s sketch_s maps_s etc_s site_s season_s ' + \
                         'filename_s filepath_s thumbnail_s pattern_s stat_s size_s'
                header = re.sub(r'_S', '_s', header.upper()).split(' ')
                csvoutput.writerow(header)

            if 'OP1' in filepath.upper():
                # print(op)
                pass

            (dtype, site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, direction, profile, mxp, etc) = \
                extract_fields(imagename, filepath)

            if dtype == 'isotope':
                pass

            if file_format == 'box':
                dtype = 'box'

            # reduce image info
            stat = stat.split(',')[0]

            output_record = [
                dtype, tno,
                roll, exp, op, sq, area, lot, fea, reg, bur, direction, profile, mxp, etc, site, season,
                filename, filepath, thumbnail, pattern, stat, filesize
            ]
            csvoutput.writerow(output_record)
