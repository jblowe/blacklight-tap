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
            return ''
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

    if 'TAP 92 NPW1 001' in filepath:
        pass

    imagename = re.sub(r', +', r',', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'tif\.tif', r'.tif', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'R##*([\d\w]+)', r'Reg\1', imagename, flags=re.IGNORECASE)


    imagename = re.sub(r'\bfea ?b', ' B', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'^Tap[_\- ]?', 'Sea', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r' *(east|west|north|south) *', r' \1 ', imagename, flags=re.IGNORECASE)
    # NKH 92 Ro 128.tif -> NKH 92 Ro1 #28.tif
    imagename = re.sub(r'Ro (\d)(\d\d)', 'Ro\1 #\2', imagename, flags=0)
    imagename = re.sub(r' *(and) *', ' and ', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'(.*)\..+?$', r'\1', imagename, flags=re.IGNORECASE)  # get rid of extension
    imagename = re.sub(r'NPW ([A-Z]) ', r'NPW Sq \1 ', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'T# ?(\d+)', r'T\1', imagename, flags=re.IGNORECASE)  # normalized T numbers
    imagename = re.sub(r'(Ro)[_ ]?(\d+)\-(\d+)', r'R\2 #\3', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'(Ro?l?l?|Op|Sq|Area|T|Lot|Fe?a?t?|Reg?)[_ ]*', r'\1', imagename, flags=re.IGNORECASE)
    # e.g. PL_R13_32.tif
    imagename = re.sub(r'([RL])(\d+)_(\d+)', r'\1\2_#\3', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'(Ro)[_ ]?(\d+)', r'R\2', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'w(\d+)', r' W\1', imagename)
    imagename = re.sub(r'(\d+)[#_](\d+)', r'\1_#\2', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'\bB ([\w, ]+)\b', r'B\1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'\bBurial ([\w, ]+)\b', r'B\1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'\bOp (\w+)\b', r'Op\1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'\bR#+', 'R#', imagename, flags=re.IGNORECASE)
    # NKH1 069, etc.
    imagename = re.sub(r'(NPW|NKH|NML|NKW|PL|KTK)(\d+) (\d+)', r'\1 Op\2 polaroid\3', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r'^(Tap|NPW|NKH|NML|NKW|PL|KTK) ?(\d+)', r'Sea\2 \1', imagename, flags=re.IGNORECASE)
    imagename = re.sub(r' ', '_', imagename)

    return imagename, filename


def extract_fields(imagename, filepath):
    (site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, etc, direction, profile, mxp) = [''] * 16

    if 'T# 15141 TAP 92 Op1 Burial 2' in filepath:
        pass
    if 'NPW M Balk Section South.ai' in filepath:
        pass
    if 'TAP 92 NPW1 001' in filepath:
        pass
    #
    if 'Isotope Project 2023' in filepath:
        # e.g. 20230214_145319.jpg, just extract date portion
        try:
            etc = re.search(r'^(\d+)', imagename)[0]
        except:
            etc = imagename
        site = 'isotope'
        dtype = 'isotope'
    else:
        parts = imagename.split('_')
        for part in parts:
            if 'TAP' == part.upper(): continue
            # this next line must go first to match PL images
            roll = match(r'\bRol([\d\.AB]+)\b', part, flags=0) if roll == '' else roll
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
            reg = match(r'\bRe?g?#([\d\w]+)', part, flags=0) if reg == '' else reg
            site = match(r'(NPW|NKH|NML|NKW|PL|KTK)', part, flags=0) if site == '' else site
            tno = match(r'^T#?([\d]+[A-Z]*)', part, flags=re.IGNORECASE) if tno == '' else tno
            bur = match(r'^Burial[# ]*([\d, \-]+)', part, flags=re.IGNORECASE) if bur == '' else bur
            bur = match(r'^\bBu?r?i?a?l?[# ]*([\d, \-]+)', part, flags=re.IGNORECASE) if bur == '' else bur
            season = match(r'Sea([\dK]+)', part, flags=re.IGNORECASE) if season == '' else season
            season = match(r'\b(86|90|92|93|94|2K8)\b', part, flags=0) if season == '' else season
            direction = match(r'(east|west|north|south)', part, flags=re.IGNORECASE) if direction == '' else direction
            profile = match(r'(balk|baulk|profile|section)', part, flags=re.IGNORECASE) if profile == '' else profile
            mxp = match(r'(map|plan)', part, flags=re.IGNORECASE) if mxp == '' else mxp

        if 'IMG_' in imagename:
            (roll, exp, bur) = [''] * 3

        if '47A' in roll:
            roll = '47'
        if '47B' in roll:
            roll = '47.2'


        if '86-9 Sq A Plan' in filepath:
            #print(filepath)
            pass


        if direction != '':
            #print(filepath)
            pass

        roll = convert(roll, 300)
        exp = convert(exp, 40)
        tno = convert(tno, 60000)
        site = site.upper()
        area = area.upper()
        op = op.upper()
        sq = sq.upper()
        direction = direction.lower()
        if fea == '0': fea = ''
        if profile != '': profile = 'profile'
        if mxp != '': mxp = 'map'
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
        # check if season is within range
        try:
            season_check = int(season)
            if season_check > 94 or season_check < 86:
                etc += season
                season = ''
        except:
            pass

        if site == 'PL':
            season = '85'

        # polaroids: e.g. TAP 92 NKH1 015.tif
        if 'polaroid' in filepath:
            dtype = 'polaroids'
        else:
            dtype = 'images'

    return dtype, site, season, tno, roll, exp, op, sq, area, lot, fea, reg, bur, direction, profile, mxp, etc
