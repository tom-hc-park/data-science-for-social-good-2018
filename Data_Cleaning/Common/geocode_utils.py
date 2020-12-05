import pandas as pd
import math

from shapely.geometry import Polygon, Point
import local_settings as local
import googlemaps

# NW: 49.222438, -122.926703
# NE: 49.216143, -122.674258
# SW: 49.002652, -122.925330
# SE: 49.001300, -122.678824
# Define the approximate city limits for Surrey
cityLimits = Polygon(((49.222438, -122.926703), (49.216143, -122.674258), (49.001300, -122.678824), (49.002652, -122.925330)))

# Google maps api client
gmaps = googlemaps.Client(local.apiKey)


def isWithin(row):
    if row.lat == 'lat':
        return False
    elif not math.isnan(float(row.lat)):
        p = Point((float(row.lat), float(row.long)))
        return p.within(cityLimits)
    else:
        return True

# input - file path for input file
# out - file path for output file.
# Removes entries where the lat/long is outside the Surrey city boundaries.
#  Does not remove entries where lat/long is empty.
def remove_outside_surrey (input, out):
    df = pd.read_csv(input)
    df['inSurrey'] = df.apply(isWithin, axis=1)
    df = df[df.inSurrey == True]
    df.to_csv(out, mode='a', encoding="utf-8")


# remove_outside_surrey("./results/Standardized_Deduped_Datasets/June_Clean_20180718_withNonSurrey.csv",
#                       "./results/Standardized_Deduped_Datasets/June_Clean_20180718.csv")
# remove_outside_surrey("./results/Standardized_Deduped_Datasets/July_Clean_20180718_withNonSurrey.csv",
#                       "./results/Standardized_Deduped_Datasets/July_Clean_20180718.csv")
# remove_outside_surrey("../../results/listings-08-09-merged.csv",
#                       "../../results/listings-08-09-mergedclean.csv")

def geocode_addr (row):
    # Components doesn't work correctly, but some bugs with this geocoder wrapper.
    if not row.address is None:
        try:
            return gmaps.geocode(row.address + "Surrey BC")
        except:
            return ""
        # return gmaps.geocode(row.address, components={'locality': 'Surrey','administrative_area_level_1':'BC','country':'CA'})

def geocode_split(row, col):
    if not row.maps_api_resp is None:
        try:
            #debug: print( row.maps_api_resp[0]['geometry']['location'][col] )
            return row.maps_api_resp[0]['geometry']['location'][col]
        #TODO: handle case where the API returns 0 results
        except:
            return

def geocode_df(df):
    df['maps_api_resp'] = df.apply(geocode_addr, axis = 1)
    df['maps_resp_lat'] = df.apply(geocode_split, axis = 1, args=('lat',))
    df['maps_resp_lng'] = df.apply(geocode_split, axis = 1, args=('lng',))
    return df


# Remove data points outside Surrey based on keywords in location
def remove_outside_Surrey_text (df, col):
    exp="(delta)|(ladner)|(langley)|(white rock)|(mission)|(burnaby)|(tsawwassen)|(coquitlam)"
    filter = df[col].str.contains(exp, case=False, na=False)
    df=df[~filter]
    return df