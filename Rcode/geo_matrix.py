#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jul 15 18:50:05 2018

@author: hyeongcheolpark
"""
import numpy as np
import scipy as sp
import pandas as pd
from scipy.spatial.distance import squareform, pdist

#import the dataframe
file='/Users/hyeongcheolpark/Desktop/DSSG/gitscripper/DSSG-2018_Housing/results/Standardized_Deduped_Datasets/Louie_Clean_20180719.csv'
result=pd.read_csv(file,encoding='latin-1')

#temporary deleting NA values.
result=result.dropna(subset=['lat', 'long'])

#From the location, make a square symmetric data frame(geo matrix) and name it geo_frame.
pairdist=pdist(result.loc[:,['lat','long']])
dist_matrix=squareform(pairdist)
geo_frame=pd.DataFrame(dist_matrix, columns=result.url.unique(), index=result.url.unique())

#set the lower triangle elements as 100.
geo_frame=geo_frame.where(np.triu(np.ones(geo_frame.shape)).astype(np.bool))
geo_frame=geo_frame.fillna(100)
geo_frame.values[[np.arange(len(geo_frame))]*2] = 100

#To set a threshold, I manually searched a pair of data set of duplicates and not exactly same location.
#1 http://vancouver.craigslist.ca/van/apa/5955387420.html
#2 http://vancouver.craigslist.ca/van/apa/5955388346.html
geo_frame.loc['http://vancouver.craigslist.ca/van/apa/5955387420.html','http://vancouver.craigslist.ca/van/apa/5955388346.html']
#value 0.00077705919980653457

#another manual checking
#http://vancouver.craigslist.ca/van/apa/5965297882.html
#http://vancouver.craigslist.ca/van/apa/5965306885.html
geo_frame.loc['http://vancouver.craigslist.ca/van/apa/5965297882.html','http://vancouver.craigslist.ca/van/apa/5965306885.html']
#value 0.00077705919980653457. Coincidence? same values.

#1 http://vancouver.craigslist.ca/van/apa/5972368145.html
#2 http://vancouver.craigslist.ca/van/apa/5972370401.html
geo_frame.loc['http://vancouver.craigslist.ca/van/apa/5972368145.html','http://vancouver.craigslist.ca/van/apa/5972370401.html']
#0.00077705919980653457

#1 http://vancouver.craigslist.ca/van/apa/5985612724.html
#2 http://vancouver.craigslist.ca/van/apa/5985613682.html
geo_frame.loc['http://vancouver.craigslist.ca/van/apa/5985612724.html','http://vancouver.craigslist.ca/van/apa/5985613682.html']
#0.00077705919980653457

#1 http://vancouver.craigslist.ca/van/apa/6180301318.html
#2 http://vancouver.craigslist.ca/van/apa/6183570990.html
geo_frame.loc['http://vancouver.craigslist.ca/van/apa/6180301318.html','http://vancouver.craigslist.ca/van/apa/6183570990.html']
#0.15484685105613388

#1 http://vancouver.craigslist.ca/van/apa/d/4-bedooms-35-bathrooms/6256686740.html
#2 http://vancouver.craigslist.ca/van/apa/d/4-bedooms-35-bathrooms/6258177420.html
geo_frame.loc['http://vancouver.craigslist.ca/van/apa/d/4-bedooms-35-bathrooms/6256686740.html','http://vancouver.craigslist.ca/van/apa/d/4-bedooms-35-bathrooms/6258177420.html']
#0.0036658953885747624

#1 https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6334178407.html
#2 https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6334179893.html
geo_frame.loc['https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6334178407.html','https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6334179893.html']
#0.032338119735098467

#1 https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6341052394.html
#2 https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6341504257.html
geo_frame.loc['https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6341052394.html','https://vancouver.craigslist.ca/van/apa/d/fully-furnished-3bdrm-25-bath/6341504257.html']
#0.032338119735098467

#1 https://vancouver.craigslist.ca/van/apa/d/3-beds-35-baths-luxury/6540668282.html
#2 https://vancouver.craigslist.ca/van/apa/d/4-beds-35-baths-luxury/6542004017.html
geo_frame.loc['https://vancouver.craigslist.ca/van/apa/d/3-beds-35-baths-luxury/6540668282.html','https://vancouver.craigslist.ca/van/apa/d/4-beds-35-baths-luxury/6542004017.html']
#0.0062286044183216009

#we will pick only pairs of urls which is bigger than 0
x_0007=list(geo_frame[geo_frame <= 0.00077705919980653457].stack().index)
x_04=list(geo_frame[geo_frame <= 0.04].stack().index)
x_max=list(geo_frame[geo_frame <= 0.15484685105613388].stack().index)
 

######Below is my trial and faliure codes.... don't mind it.########
#results = {}
#for k,v in x:
#    results.setdefault(k, []).append(v)
    
#under certain thresholds, I would like to pick the list of lists. 

#temp_set=set()
#threshold=0.3
#for i in range(geo_frame.shape[0]-1):
#    for j in range(i+1,geo_frame.shape[1]):
#        if geo_frame.iloc[i,j] <= threshold:
#            temp_subset=set()
#            temp_subset.add(result.url[i])
#            temp_subset.add(result.url[j])#What's wrong with result.url[71]?
#        temp_set=temp_subset|temp_set
    
#temp_set.add(temp_set)

#A new way, less computational method 
        
#def checkthld(i,threshold):
    #i is each row
    #j is each column. 
#    if i<j: #for each row, we look at elements whose indices bigger than the index of row.
        #give me the indics of columns for each row
#    return(#dict of key: i and value: many j values)
	#i wanna return dict of key: the row, and value: the columns 

#geo_frame.apply(checkthld, axis=1,args=(threshold,)) 
#b is a Series, deleting redundant lower triangle values.
#b=geo_frame.mask(np.triu(np.ones(geo_frame.shape)).astype(bool)).stack()

#from collections import OrderedDict, defaultdict
#b.to_dict(OrderedDict)
#x is a list of tuples, but including redundant values 


#This is to make a dict(key and value, but redundant values included)
