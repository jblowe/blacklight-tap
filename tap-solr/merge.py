
import pandas as pd
pd.options.display.float_format = '%d'.format

import sys
  
# reading two csv files 
data1 = pd.read_csv(sys.argv[1], sep='\t')
data2 = pd.read_csv(sys.argv[2], sep='\t')
  
# using merge function by setting how='inner' 
output1 = pd.merge(data1, data2,  
                   on=sys.argv[4],
                   how='outer')

output1['ROLL_s'] = output1['ROLL_s'].map('{:,}'.format)
output1['EXP_s'] = output1['EXP_s'].map('{:,}'.format)
# displaying result
#open(sys.argv[3], 'w')
output1.to_csv(sys.argv[3], sep='\t')

