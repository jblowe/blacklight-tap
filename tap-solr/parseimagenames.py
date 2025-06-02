import re
import sys
from collections import defaultdict
import csv

delim = '\t'


def match(pattern, value, flags):
    m = re.search(pattern, value, flags=flags)
    if m == None:
        return ''
    else:
        # print(pattern,': ', value,'= ', m[1])
        return m[1]


def convert(str):
    try:
        # there are a few floats in there
        if '.' in str:
            return str
        return int(str)
    except:
        return str


input_file = sys.argv[1]
output_file = sys.argv[2]
with open(input_file, 'r') as inputfile:
    csvinput = csv.reader(inputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    with open(output_file, 'w') as outputfile:
        csvoutput = csv.writer(outputfile, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        for i, row in enumerate(csvinput):

            (tap_dir, tap_id, derivative, stat, filepath, pattern) = [''] * 6
            #(filename, pattern) = row
            (tap_dir, tap_id, derivative, stat, filepath) = row
            thumbnail = f'/images/{tap_dir}/{derivative}'
            thumbnail = thumbnail.replace('#', '_')
            imagename = filepath
            imagename = re.sub(r'^.*/', '', imagename) # remove pathname
            filename = imagename
            # special cases
            # Tap92 33 NPW #37.tif
            imagename = re.sub(r'Tap(\d+) (\d+) (\w+ )#(\d+)', r'Tap\1 \3 R\2 #\4', imagename, flags=re.IGNORECASE)
            # NKH 92 Ro 10-03.tif
            #imagename = re.sub(r'NKH (\d+) Ro (\d+)\-(\d+)', r'NKH \1 R\2 #\3', imagename, flags=re.IGNORECASE)
            # NKH 92 Ro2-01.tif
            #imagename = re.sub(r'NKH (\d+) Ro(\d+)\-(\d+)', r'NKH \1 R\2 #\3', imagename, flags=re.IGNORECASE)
            # Obj# 22
            # R##566D5
            imagename = re.sub(r'R##([\d\w]+)', r'Reg\1', imagename, flags=re.IGNORECASE)

            imagename = re.sub(r'^Tap[_\- ]?', 'Sea', imagename, flags=re.IGNORECASE)
            imagename = re.sub(r'(.*)\..+?$', r'\1', imagename, flags=re.IGNORECASE) # get rid of extension

            imagename = re.sub(r'T#(\d+)', r'T\1', imagename, flags=re.IGNORECASE)  # normalized T numbers
            imagename = re.sub(r'(Ro?l?l?|Op|Sq|Area|T|Lot|Fe?a?t?|Reg?)[_ ]+', r'\1', imagename, flags=re.IGNORECASE)
            imagename = re.sub(r'([RL])(\d+)_(\d+)', r'\1\2_#\3', imagename, flags=re.IGNORECASE)
            # e.g. NKH_92_Ro_534.thumb.jpg
            imagename = re.sub(r'(Ro)[_ ]?(\d+)\-(\d+)', r'R\2_#\3', imagename, flags=re.IGNORECASE)
            imagename = re.sub(r'(Ro)[_ ]?(\d+)', r'R\2', imagename, flags=re.IGNORECASE)
            imagename = re.sub(r'(\d+)[#_](\d+)', r'\1_#\2', imagename, flags=re.IGNORECASE)
            imagename = re.sub(r'^(NPW|NKH|NML|NKW|PL|KTK) ?(\d+)', r'Sea\2 \1', imagename, flags=re.IGNORECASE)
            imagename = re.sub(r' ', '_', imagename)

            parts = imagename.split('_')

            if i == 0:
                header = 'dtype_s\tt_s\troll_s\texp_s\top_s\tsq_s\tarea_s\tlot_s\tfea_s\treg_s\tburial_s\tetc_s\tsite_s\tyear_s\tfilename_s\tfilepath_s\tthumbnail_s\tpattern_s\tdirectory_s'.upper()
                header = re.sub(r'_S', '_s', header).split('\t')
                csvoutput.writerow(header)

            (site, season, tno, roll, exp, op, sq, area, lot, fea, reg, site, season, bur, etc) = [''] * 15
            for part in parts:
                if 'TAP' == part.upper(): continue
                roll = match(r'[RL]o?l?l?(\d+\.?\d?)', part, flags=re.IGNORECASE) if roll == '' else roll
                exp = match(r'#(\d+)', part, flags=re.IGNORECASE) if exp == '' else exp
                roll = match(r'R(\d+)[\-#](\d+)', part, flags=re.IGNORECASE) if roll == '' else roll
                exp = match(r'R\d+[\-#](\d+)', part, flags=re.IGNORECASE) if exp == '' else exp
                op = match(r'Op([\d\w]+)', part, flags=re.IGNORECASE) if op == '' else op
                sq = match(r'Sq([\d\w]+)', part, flags=re.IGNORECASE) if sq == '' else sq
                area = match(r'A[re]a([\d\w]+)', part, flags=re.IGNORECASE) if area == '' else area
                lot = match(r'Lot(\d+)', part, flags=re.IGNORECASE) if lot == '' else lot
                fea = match(r'Fe?a?t?(\d+)', part, flags=re.IGNORECASE) if fea == '' else fea
                reg = match(r'Reg?([\d\w]+)', part, flags=re.IGNORECASE) if reg == '' else reg
                site = match(r'(NPW|NKH|NML|NKW|PL|KTK)', part, flags=re.IGNORECASE) if site == '' else site
                tno = match(r'^T([\dA-Z]+)', part, flags=re.IGNORECASE) if tno == '' else tno
                bur = match(r'Bu?r?(\d+)', part, flags=re.IGNORECASE) if bur == '' else bur
                season = match(r'Sea(\d+)', part, flags=re.IGNORECASE) if season == '' else season
                # print "p\t"

            roll = convert(roll)
            exp = convert(exp)
            tno = convert(tno)
            site = site.upper()
            etc = ''

            # polaroids: TAP 92 NKH1 015.tif
            if 'polaroid' in filepath:
                dtype = 'polaroids'
            else:
                dtype = 'images'

            output_record = [
                dtype, tno,
                roll, exp, op, sq, area, lot, fea, reg, bur, etc, site, season,
                filename, filepath, thumbnail, pattern, tap_dir
            ]
            csvoutput.writerow(output_record)
