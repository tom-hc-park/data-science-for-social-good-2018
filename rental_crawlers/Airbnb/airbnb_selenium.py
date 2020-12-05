# -*- coding: utf-8 -*-
from __future__ import absolute_import

import scrapy

import time

from selenium import webdriver

import re

import csv

import pandas as pd



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



class airbnbSeleniumScraper:

    #TODO: Auto-extraction of this url to be done
    start_url = 'https://www.airbnb.ca/s/Surrey--BC/homes?refinement_paths%5B%5D=%2Fhomes&allow_override%5B%5D=&map_toggle=true&ne_lat=49.216143&ne_lng-122.674258&sw_lat=49.002652&sw_lng=-122.925330&zoom=11&search_by_map=true&s_tag=nzl-4o23'

    driver = webdriver.Firefox()
    sys_sleep_time = 3 # This time is very critical

    #TODO: Auto-extraction of this number to be done
    result_page_total_number = 17

    posting_links_arr = []
    posting_pages_arr = []
    search_result_pages = []
    search_result_pages.append(start_url)

    for i in range(1, result_page_total_number):
        result_page_url = start_url + '&section_offset=' + str(i)
        search_result_pages.append(result_page_url)

    print('Finished getting all search result pages')

    for result_url in search_result_pages:
        driver.get(result_url)
        time.sleep(sys_sleep_time)

        element_xpathes = '//meta[@itemprop="url"]'
        elements = driver.find_elements_by_xpath(element_xpathes)

        for element in elements:
            try:
                element_link_str = element.get_attribute('content')
                element_link = 'https://' + element_link_str

                posting_links_arr.append(element_link)

            except AttributeError as AE:
                print(AE)

        print(len(posting_links_arr))


    lat_lon_parsing_error_ids = []

    for link in posting_links_arr:
        try:

            # Getting Airbnb ID
            id_str = re.findall(r'\/([0-9]*?)\?', link)[0]

            print('Connecting to: ' + id_str)
            driver.get(link)
            # time.sleep(randint(1, 10))

            driver.execute_script("window.scrollTo(0, 6000);")
            print('Scrolled down: ' + id_str)

            time.sleep(sys_sleep_time)  # This time is very critical

            print('Making item structure for: ' + id_str)

            item = AirbnbItem()


            # Getting lat-lon
            latlon_xpath = '//a[contains(@href, "maps.google.com")]'
            latlon_elements = driver.find_elements_by_xpath(latlon_xpath)

            # extra_wait_rounds = 0
            # while (len(latlon_elements) < 1) & (extra_wait_rounds < 8) :
            #     time.sleep(0.25)
            #     extra_wait_rounds =+ 1


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
                lat_lon_parsing_error_ids.append(id_str)
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
            item['url'] = link

            posting_pages_arr.append(item)

            time.sleep(sys_sleep_time)

        except RuntimeError as RE:
            print(RE)
            break

    driver.close()

    print('Trying writing to csv')
    df = pd.DataFrame(posting_pages_arr)
    df.to_csv('airbnb.csv', index=False)

    print('First attemp lat-lon failed: ')
    print(lat_lon_parsing_error_ids)








