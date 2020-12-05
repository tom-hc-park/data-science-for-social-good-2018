# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://doc.scrapy.org/en/latest/topics/item-pipeline.html

'''
Pipeline for processing CLItem scraped from CL
'''
import re


class CLPipeline(object):
    def process_item(self, item, spider):
        if spider.name == "cl_listings":
            if not item['sqft'] is None:
                item['sqft'] = item['sqft'].strip()
                roomsqft = item['sqft'].split("-")
                if len(roomsqft) == 2:
                    item['rooms'] = roomsqft[0]
                    item['sqft'] = roomsqft[1]
                elif "br" in roomsqft[0]:
                    item['rooms'] = roomsqft[0]
                    item['sqft'] = None
                elif "ft" in roomsqft[0]:
                    item['rooms'] = None
                    item['sqft'] = roomsqft[0]

            if "rds/roo/" in item['url']:
                item['rooms'] = "private room"
        return item


'''
Pipeline for processing CLItem scraped from KJ
'''


class KJPipeline(object):
    def process_item(self, item, spider):
        if spider.name == "kj_listings":
            item['rooms'] = self.getHousingType(item)
        return item

    def getHousingType(self, item):
        url = item['url']
        try:
            house_type = re.search('./v-(.+?)-([apartments]|[rental])', url).group(1)
        except AttributeError:
            house_type = ''

        house_type = house_type.replace("-", " ")

        if not "bedroom" in house_type and "room" in house_type:
            house_type = "private room"

        return house_type
