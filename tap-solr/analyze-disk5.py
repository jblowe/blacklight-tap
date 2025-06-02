import sys, csv, shutil

delim = "\t"
errors = 0

projects = 'PL TAP94 TAP90 TAP86 TAP92 NKH TNOS NPW TAP2K8 NML'.split(' ')


def move_file(filename, project):
    shutil.move(f'thumbnails/{filename}', f'projects/{project}/{filename}')


with open(sys.argv[2], 'w') as f2:
    writer = csv.writer(f2, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255), escapechar='\\')
    with open(sys.argv[1], 'r') as f1:
        reader = csv.reader(f1, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
        try:
            for lineno, row in enumerate(reader):
                project = row[0]
                if project in projects:
                    try:
                        move_file(row[1], project)
                        writer.writerow(row)
                    except:
                        writer.writerow(row + ['failed'])
                        errors += 1
                else:
                    pass
        except:
            writer.writerow([lineno, 'failed'])
            errors += 1

if errors > 0:
    print
    print("%s errors seen" % errors)
    print
