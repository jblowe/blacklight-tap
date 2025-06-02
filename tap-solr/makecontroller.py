FIELDS = '''T_s
ROLL_s
EXP_s
SITE_s
YEAR_s
OP_s
AREA_s
LEVEL_s
LOT_s
DATE_s
REVISIOND_s
NOTES_s
DUPLICATED_s
EXCAVATOR_s
FEA_s
NOTES2_s
OBJ_s
PHOTOTYPE_s
REG_s'''

CONFIGS = [
    "config.add_facet_field 'FIELD', label: 'LABEL', limit: true",
    "config.add_show_field 'FIELD', label: 'LABEL'",
    "config.add_index_field 'FIELD', label: 'LABEL'"
]

for C in CONFIGS:
    print('    # ')
    for F in FIELDS.split('\n'):
        X = C.replace('FIELD', F)
        X = X.replace('LABEL', F.replace('_txt', ''))
        print('    ',X)
