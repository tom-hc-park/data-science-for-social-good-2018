# -*- coding: utf-8 -*-
from __future__ import absolute_import

import time

from selenium import webdriver

import re

import pandas as pd

import scrapy


class AirbnbItem(scrapy.Item):

    airbnbID = scrapy.Field()
    title = scrapy.Field()
    location = scrapy.Field()
    housing_type = scrapy.Field()
    price = scrapy.Field()
    date  = scrapy.Field()
    lat = scrapy.Field()
    lon = scrapy.Field()
    description = scrapy.Field()
    url = scrapy.Field()

    pass


sys_sleep_time = 3


class geoInfoTest:

    driver = webdriver.Firefox()

    test_url = ''

    driver.get(test_url)

    driver.execute_script("window.scrollTo(0, 6000);")
    time.sleep(3.5) #This time is very critical


    latlon_xpath = '//a[contains(@href, "maps.google.com")]'
    latlon_element = driver.find_elements_by_xpath(latlon_xpath)
    latlon_link = latlon_element[0].get_attribute('href')

    str_splits = re.findall(r'\=(.*?)\&', latlon_link)
    latlon = str_splits[0]
    lat = latlon.split(",")[0]
    lon = latlon.split(",")[1]


    print(latlon_link)

    driver.close()



class geoInfoExtractAndWrite:

    driver = webdriver.Firefox()

    #TODO: want to de-hard-code this
    id_arr = []

    posting_pages_arr = []
    fail_arr = []


    for id_str in id_arr:

        url_str = 'https://www.airbnb.ca/rooms/' + id_str + '?location=Surrey%2C%20BC'

        try:
            print('Connecting to: ' + id_str)
            driver.get(url_str)

            driver.execute_script("window.scrollTo(0, 6000);")
            print('Scrolled down: ' + id_str)

            time.sleep(sys_sleep_time)

            print('Making item structure for: ' + id_str)

            item = AirbnbItem()

            # Getting lat-lon
            latlon_xpath = '//a[contains(@href, "maps.google.com")]'
            latlon_elements = driver.find_elements_by_xpath(latlon_xpath)

            try:
                latlon_link = latlon_elements[0].get_attribute('href')

                str_splits = re.findall(r'\=(.*?)\&', latlon_link)
                latlon = str_splits[0]
                lat = latlon.split(",")[0]
                lon = latlon.split(",")[1]

                item['lat'] = lat
                item['lon'] = lon

            except IndexError as ie:
                print('Error when extracting geo info for: ' + id_str)
                fail_arr.append(id_str)
                item['lat'] = ''
                item['lon'] = ''
                continue


            item['airbnbID'] = id_str
            item['title'] = ''
            item['location'] = ''
            item['housing_type'] = ''
            item['price'] = ''
            item['date'] = ''
            item['description'] = ''
            item['url'] = url_str

            posting_pages_arr.append(item)

            time.sleep(sys_sleep_time)


        except RuntimeError as RE:
            print(RE)
            break

    driver.close()


    print('Trying writing to csv')
    df = pd.DataFrame(posting_pages_arr)

    with open('airbnb.csv', 'a') as file:
        df.to_csv(file, header=False, index=False)

    print('Additional attemp lat-lon failed: ')
    print(fail_arr)









