# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://doc.scrapy.org/en/latest/topics/items.html

import scrapy

'''
Custom definition for fields for Item used by the CL_listings spider.
    title: title of listing
    location: address or city or neighborhood provided in the posting. Optional.
    housing_type: has the format [# rooms] - [sq ft] (e.g. 1br - 650ft2). Optional.
    price: rental price per month
    date: date of original posting
    lat: approximate latitude. Optional.
    longitude: approximate longitude. Optional.
    description: body of the listing
    url: link to the listing
'''


class CLItem(scrapy.Item):
    title = scrapy.Field()
    location = scrapy.Field()
    rooms = scrapy.Field()
    sqft = scrapy.Field()
    price = scrapy.Field()
    date = scrapy.Field()
    lat = scrapy.Field()
    long = scrapy.Field()
    description = scrapy.Field()
    url = scrapy.Field()
    address = scrapy.Field()
    city = scrapy.Field()
    province = scrapy.Field()
    country = scrapy.Field()
    source = scrapy.Field()
