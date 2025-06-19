import sys, csv

delim = "\t"

inputFile1 = sys.argv[1]
inputFile2 = sys.argv[2]
file1_key = int(sys.argv[3])
file2_key = int(sys.argv[4])

f1 = csv.reader(open(inputFile1, 'r'), delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
f2 = csv.reader(open(inputFile2, 'r'), delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))

file1 = {}
alreadyseen = {}
counts = {}
max = 0

counts['file1'] = 0
counts['file2'] = 0
counts['unmatched'] = 0
counts['matched'] = 0
counts['duplicates'] = 0

for lineno, ci in enumerate(f1):
    counts['file1'] += 1
    file1[ci[file1_key]] = ci

for lineno, ci in enumerate(f2):
    # print lineno,"\t",ci
    counts['file2'] += 1
    if ci[file2_key] in file1:
        if ci[file2_key] in alreadyseen:
            # print('%s already seen, not added' % ci[file2_key])
            counts['duplicates'] += 1
        else:
            print(delim.join(file1[ci[file2_key]]))
            alreadyseen[ci[file2_key]] = ci
            max = len(file1[ci[0]])
            counts['matched'] += 1
    else:
        # non matching lines in file 2 to go into the bit bucket
        counts['unmatched'] += 1
        pass


counts['max'] = max
for stat, value in sorted(counts.items()):
    print("%s: %s" % (stat, value), file=sys.stderr)
