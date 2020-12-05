import config
from datetime import datetime, timedelta
from pathlib import Path
import rpy2.robjects as robj
import rpy2.robjects.packages as rpkg
from Data_Cleaning.DeDuplication import deduplication_on_urls_Refactored as dedup
from Common.geocode_utils import remove_outside_surrey, remove_outside_Surrey_text
import pandas as pd
import glob
import os

# Input File Path
lastmonth = datetime.now().replace(day=1)-timedelta(days=1)
date = lastmonth.strftime("%Y-%m")
f = Path(config.ROOT_DIR)/'results'/'raw'/f"listings-{date}.csv"

# pandas2ri.activate()

CLEAN = False

# ============================================= Data Cleaning ==========================================================
# 1.1 - Remove data points outside of surrey based on lat/long, and location text
out1 = Path(config.ROOT_DIR)/'results'/'temp'/'out1_1.csv'
remove_outside_surrey(f, out1)
df = pd.read_csv(out1)
df = remove_outside_Surrey_text(df, col='location')
df.to_csv(Path(config.ROOT_DIR)/'results'/'temp'/'out1_2.csv',encoding='utf-8')

# 1.2 - Call the R script for removing data points outside of Surrey
rscript1 = Path(config.ROOT_DIR)/'Rcode'/'surrey_nonsurrey_classifier.R'
nonSurreyR = robj.r.source(str(rscript1))

# 2 - Deduplicate listings based on URL
dedup._Dd_Url_csv(Path(config.ROOT_DIR)/'results'/'temp'/'out2.csv',
               Path(config.ROOT_DIR)/'results'/'temp'/'out3.csv')

# 3 - Clean and standardize price and sqft
rscript2 = Path(config.ROOT_DIR)/'Rcode'/'price_sqft_rooms_standarization.R'
robj.r.source(str(rscript2))

# 4 - Deduplication based on Record Linkage
rscript3 = Path(config.ROOT_DIR)/'Rcode'/'RL_for_a_month_data.R'
robj.r.source(str(rscript3))

# # 5 - MICE on monthly data set
# rscript4 = Path(config.ROOT_DIR)/'Rcode'/'Mice_for_futher_investigation.R'
# robj.r.source(str(rscript4))
#
#

# Delete and remove all the temp files (control with CLEAN)
if (CLEAN):
    dir = Path(config.ROOT_DIR)/'results'/'temp'/'*'
    files = glob.glob(str(dir))
    for f in files:
        os.remove(f)

# # Custom import an R file as a package and call its methods
# Required R libs
# r_base = rpkg.importr('base')
# utils = rpkg.importr("utils")
# f2 = open(filename)
# s = f2.read()
# print(s)
# nonSurreyR = rpkg.SignatureTranslatedAnonymousPackage(s, 'nonSurrey')
# csv_in = nonSurreyR.nonSurrey_setup(f)
# class_res = nonSurreyR.classifier

# Classifiers
