from pathlib import Path
import pandas as pd
import spacy
import config
from Data_Cleaning.Common import nlp_utils as nutils
from Data_Cleaning.Common import geocode_utils as geocode
from postal.parser import parse_address
import numpy as np
import matplotlib.pyplot as plt

# APPLY Functions
def address_parser(row, colname):
    return parse_address(str(row[colname]))

#Calculates Euclidean distance between 2 pandas Series of lat-long points
def dist(row):
    pt1 = np.array([float(row.lat), float(row.long)])
    pt2 = np.array([row.maps_resp_lat, row.maps_resp_lng])
    return np.linalg.norm(pt1-pt2)

# Main functions for address extraction
def fill_address(row, input_col, output_col='address'):
    if pd.isna(row[output_col]):
        temp = dict(row[input_col])
        addr_dict = {v:k for k,v in temp.items()}
        try:
            house_no = addr_dict.get("house_number")
            road = addr_dict.get("road")
            return house_no + " " + road
        except:
            return

# input_col = name of column containing address to be parsed
# output _col = name of column to store parsed values
def parse_column(df, input_col, output_col):
    try:
        df[output_col] = df.apply(address_parser, axis=1, args=(input_col,))
    except TypeError:
        df[output_col] = "skipped"
    return df

# listings: pandas df containing rental listings
# mrkt_rentals: filepath to private list of market rentals
# checks if address in listings is found in market_rentals
def check_address(listings, mrkt_rentals):
    sum = 0
    df_listings = listings.dropna(subset=['address'])
    for value in mrkt_rentals.ADDRESS:
        result = df_listings.address.str.contains(value, case=False, regex=False)
        sum += result.sum()
    return sum

#Returns the number of points where distance between provided address and provided lat-long is greater than the threshold.
def check_distance(df, threshold):
    dist_df = df[['lat', 'long', 'maps_resp_lat', 'maps_resp_lng']]
    dist_df = dist_df.dropna()

    dist_df['distance'] = dist_df.apply(dist, axis=1)

    df = pd.concat([df, dist_df['distance']], axis=1, join="inner")
    print(df.head())
    #Visualization
    plt.hist(dist_df['distance'])
    plt.show()
    return sum(dist_df['distance']>threshold), dist_df.count(axis=0), df

#define filepaths here
f = Path(config.ROOT_DIR)/'results'/'Standardized_Deduped_Datasets'/'2000samples_labeled_20181021.csv'
mrkt_rentals = pd.read_csv(Path('C:/Users/jocel/DSSG-2018')/"MarketRental_May2018.csv")

df = pd.read_csv(f)
#parse address from location column
df = parse_column(df, 'location', 'loc_address')
df["address"] = df.apply(fill_address, axis=1, args=('loc_address',))

#remove stopwords
df = nutils.remove_stopwords(df, 'description', 'clean_description')

#geocode based on address
df = geocode.geocode_df(df)

#print(check_address(df,mrkt_rentals))
res1, res2, res3 = check_distance(df, 0.0001)
print(str(res1))
print(str(res2))

#output csv
output_path_root = Path(config.ROOT_DIR)/'results'/'address_parsing'
df.to_csv(output_path_root/'location_address.csv', encoding="utf-8")
res3.to_csv(output_path_root/'distances.csv', encoding="utf-8")