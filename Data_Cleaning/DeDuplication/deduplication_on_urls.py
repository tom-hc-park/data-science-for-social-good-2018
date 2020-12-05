import csv
import datetime

file_name_in = 'listings-2018-07.csv'

date = datetime.datetime.today().strftime('%Y%m%d')
file_name_out = 'July_Clean_'+date+'.csv'

#unstandardized_str = 'bathsbedscraigIddatelatitudelinklongitudepricesizetitleinSurrey'

def dedupUrl(file_name_in, file_name_out):
    with open(file_name_in, 'r', encoding="utf-8", newline='') as input_file, \
            open(file_name_out, 'w', encoding='utf-8', newline='') as output_file:


        reader = csv.reader(input_file)
        writer = csv.writer(output_file)
        data_content = list(reader)


        seen = []
        # seen.append(data_content[0])

        url_set = set()


        for row in data_content:
            dry_first_grid = row[0].replace(' ', '')
            #len_dry_first_grid = len(dry_first_grid)
            if (dry_first_grid == 'address') or (row[16] in url_set):
                continue
            else:
                seen.append(row)
                url_set.add(row[14])


        output_file = writer.writerows(seen)


        # print(len(seen))
