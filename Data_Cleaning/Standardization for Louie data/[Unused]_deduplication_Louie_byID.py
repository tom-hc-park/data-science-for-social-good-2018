
import csv
import datetime

file_name_in = 'merged_cleaned_Louie.csv'

# script_dir = os.path.dirname(__file__)
# file_path = os.path.join(script_dir, file_name) #File dir set to script dir
#
# try:
#     data_set = pd.read_csv(file_path, encoding='utf-8')
#     print(type(data_set))
#
# except TypeError as ex:
#     print(ex)

date = datetime.datetime.today().strftime('%Y%m%d')
file_name_out = 'deDuplicated_Louie_byID_'+date+'.csv'

#unstandardized_str = 'bathsbedscraigIddatelatitudelinklongitudepricesizetitleinSurrey'


with open(file_name_in, 'r') as input_file, open(file_name_out, 'w') as output_file:


    reader = csv.reader(input_file)
    writer = csv.writer(output_file)
    data_content = list(reader)


    seen = []
    seen.append(data_content[0])

    id_set = set()


    for row in data_content:
        dry_second_grid = row[1].replace(' ', '')
        #len_dry_first_grid = len(dry_first_grid)
        if (dry_second_grid == 'baths') or (row[3] in id_set):
            continue
        else:
            seen.append(row)
            id_set.add(row[3])


    output_file = writer.writerows(seen)


    # print(len(seen))
