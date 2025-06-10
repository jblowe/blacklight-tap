import re


def match(pattern, value, flags):
    m = re.search(pattern, value, flags=flags)
    if m == None:
        return ''
    else:
        # print(pattern,': ', value,'= ', m[1])
        return m[1]


def convert(str, limit):
    try:
        # there are a few floats in there
        if '.' in str:
            return str
        if int(str) > limit:
            return str
        return int(str)
    except:
        return str


def parse_image_filename(filepath):
    imagename = filepath
    imagename = re.sub(r'^.*/', '', imagename)  # remove pathname
    filename = imagename
    # special cases
    # Tap92 33 NPW #37.tif
    imagename = re.sub(r'Tap(\d+) (\d+) (\w+ )#(\d+)', r'Tap\1 \3 R\2 #\4', imagename, flags=re.IGNORECASE)
    # NKH 92 Ro 10-03.tif
    # imagename = re.sub(r'NKH (\d+) Ro (\d+)\-(\d+)', r'NKH \1 R\2 #\3', imagename, flags=re.IGNORECASE)
    # NKH 92 Ro2-01.tif
    # imagename = re.sub(r'NKH (\d+) Ro(\d+)\-(\d+)', r'NKH \1 R\2 #\3', imagename, flags=re.IGNORECASE)
    # Obj# 22
    # R##566D5
    imagename = re.sub(r', ', r',', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'R##([\d\w]+)', r'Reg\1', imagename, flags=re.IGNORECASE)

    imagename = re.sub(r'^Tap[_\- ]?', 'Sea', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'(.*)\..+?$', r'\1', imagename, flags=re.IGNORECASE)  # get rid of extension

    imagename = re.sub(r'T#(\d+)', r'T\1', imagename, flags=re.IGNORECASE)  # normalized T numbers
    imagename = re.sub(r'(Ro?l?l?|Op|Sq|Area|T|Lot|Fe?a?t?|Reg?)[_ ]*', r'\1', imagename, flags=re.IGNORECASE)
    # e.g. PL_R13_32.tif
    imagename = re.sub(r'([RL])(\d+)_(\d+)', r'\1\2_#\3', imagename, flags=re.IGNORECASE)
    # e.g. NKH_92_Ro_534.thumb.jpg
    imagename = re.sub(r'(Ro)[_ ]?(\d+)\-(\d+)', r'R\2_#\3', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'(Ro)[_ ]?(\d+)', r'R\2', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'(\d+)[#_](\d+)', r'\1_#\2', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'\bB ([\w, ]+)\b', r'B\1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'\bOp (\w+)\b', r'Op\1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'^(NPW|NKH|NML|NKW|PL|KTK) ?(\d+)', r'Sea\2 \1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r' ', '_', imagename)

    return imagename, filename


def extract_fields(imagename, filepath):
    (site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, etc) = [''] * 13

    parts = imagename.split('_')
    for part in parts:
        if 'TAP' == part.upper(): continue
        # this next line must go first to match PL images
        roll = match(r'\b([RL]\d+)', part, flags=0) if 'PL' in imagename and roll == '' else roll
        roll = match(r'\bRo?l?l?(\d+\.?\d?)', part, flags=re.IGNORECASE) if roll == '' else roll
        roll = match(r'\bR(\d+)[\-#]\d+', part, flags=re.IGNORECASE) if roll == '' else roll
        exp = match(r'#(\d+)', part, flags=re.IGNORECASE) if exp == '' else exp
        exp = match(r'\bR\d+[\-#](\d+)', part, flags=re.IGNORECASE) if exp == '' else exp
        op = match(r'\bOp([\d+][\w]?)', part, flags=re.IGNORECASE) if op == '' else op
        op = match(r'\bOp(\w+)\b', part, flags=re.IGNORECASE) if op == '' else op
        sq = match(r'\bSq([\d\w]+)', part, flags=re.IGNORECASE) if sq == '' else sq
        area = match(r'\bAr?e?a?(\w+)\b', part, flags=re.IGNORECASE) if area == '' else area
        lot = match(r'Lot(\d+)', part, flags=re.IGNORECASE) if lot == '' else lot
        fea = match(r'\bFe?a?t?(\d+)', part, flags=re.IGNORECASE) if fea == '' else fea
        reg = match(r'\bReg?([\d\w]+)', part, flags=re.IGNORECASE) if reg == '' else reg
        site = match(r'(NPW|NKH|NML|NKW|PL|KTK)', part, flags=re.IGNORECASE) if site == '' else site
        tno = match(r'^T#?([\d]+[A-Z]*)', part, flags=re.IGNORECASE) if tno == '' else tno
        bur = match(r'^\bBu?r?i?a?l?[# ]*([\d, ]+)', part, flags=re.IGNORECASE) if bur == '' else bur
        season = match(r'Sea(\d+)', part, flags=re.IGNORECASE) if season == '' else season
        season = match(r'\b(86|90|92|93|94)\b', part, flags=re.IGNORECASE) if season == '' else season
        # print "p\t"

    if 'IMG_' in imagename:
        (roll, exp, bur) = [''] * 3

    if 'Op B - B 3, 4.pdf' in filepath:
        #print(filepath)
        pass

    roll = convert(roll, 300)
    exp = convert(exp, 40)
    tno = convert(tno, 40000)
    site = site.upper()
    area = area.upper()
    op = op.upper()
    sq = sq.upper()
    etc = ''
    if site == '':
        for s in 'NPW|NKH|NML|NKW|PL|KTK'.split('|'):
            if s in filepath:
                site = s
                break

    if season == '':
        for s in '86 90 92 93 94'.split(' '):
            if f' {s} ' in filepath or f'TAP{s} ' in filepath.upper():
                season = s
                break

    # polaroids: e.g. TAP 92 NKH1 015.tif
    if 'polaroid' in filepath.lower():
        dtype = 'polaroids'
    else:
        dtype = 'images'

    return dtype, site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, etc
