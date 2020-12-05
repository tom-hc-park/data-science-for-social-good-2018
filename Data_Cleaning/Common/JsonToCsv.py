from glob import glob
import pandas
from shapely.geometry import Polygon, Point

# NW: 49.222438, -122.926703
# NE: 49.216143, -122.674258
# SW: 49.002652, -122.925330
# SE: 49.001300, -122.678824

cityLimits = Polygon(((49.222438, -122.926703), (49.216143, -122.674258), (49.001300, -122.678824), (49.002652, -122.925330)))


def isWithin(row):
    p = Point((row.latitude, row.longitude))
    return p.within(cityLimits)

#replace with directory where json files are stored
dir = 'C:/Users/jocel/DSSG-2018/vancouver-cl-rentals'
for f in glob(dir + '/*.json'):
    try:
        with open(f) as data_file:
            df = pandas.read_json(data_file)
            df = df[(df.latitude.isnull() == False) & (df.longitude.isnull() == False)]
            df['inSurrey'] = df.apply(isWithin, axis=1)
            df = df[df.inSurrey == True]
            df.to_csv(dir+'/merged.csv', mode='a', encoding="utf-8")

    except ValueError:
        print("File error in: " + f)

