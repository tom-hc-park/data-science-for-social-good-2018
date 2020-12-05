import csv
import datetime
import os
import pandas

# Uncomment this code block to run the script manually
# # Inter-step csv file coded here
# file_name_in = 'out2.csv'
#
#
# # Checking validity of input file
# try:
#
#     # Current working dir, change if input file in different dir
#     owd = os.getcwd()
#     file_dir_in = owd + '/' + file_name_in
#     assert(os.path.exists(file_dir_in))
# except:
#     print('Input file not found')
#
# date = datetime.datetime.today().strftime('%Y%m%d')
# file_name_out = 'Dduped_on_url'+date+'.csv'


# @input and @output files are all .csv
def _Dd_Url_csv(file_name_in, file_name_out):

    with open(file_name_in, 'r', encoding="utf-8", newline='') as input_file, \
            open(file_name_out, 'w', encoding='utf-8', newline='') as output_file:

        reader = csv.reader(input_file)
        writer = csv.writer(output_file)
        data_content = list(reader)

        seen = []

        url_set = set()

        urlCol_index = data_content[0].index('url')
        #print(urlCol_index)

        for row in data_content:
            dry_first_grid = row[0].replace(' ', '')


            if (dry_first_grid == 'address') or (row[urlCol_index] in url_set):
                continue
            else:
                seen.append(row)
                url_set.add(row[14])

        output_file = writer.writerows(seen)


# @input and @output are pandas.dataframe
def _Dd_Url_df(df):
    return df.drop_duplicates(subset='url')
