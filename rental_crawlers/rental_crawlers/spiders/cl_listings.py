# -*- coding: utf-8 -*-
import scrapy
from scrapy.spiders import CrawlSpider, Rule
from scrapy.linkextractors import LinkExtractor
from rental_crawlers.items import CLItem


class CLSpider(CrawlSpider):

    name = 'cl_listings'
    allowed_domains = ['vancouver.craigslist.ca']
    start_urls = [
        'https://vancouver.craigslist.ca/search/rds/apa', #apartments
        'https://vancouver.craigslist.ca/rds/roo/' #rooms for rent
    ]

    '''
    Rules for automatically following the links to the listing, and going to the next listing. 
    '''
    rules = (
        Rule(LinkExtractor(allow=(), restrict_xpaths=('//a[@class="result-title hdrlnk"]')), follow=True, callback='parse_listings'),
        Rule(LinkExtractor(allow=(), restrict_xpaths=('//a[contains(@class, "button next")]')), follow=True, callback='parse_listings')
    )

    custom_settings = {
        'LOG_LEVEL': 'INFO',
        'DELTAFETCH_ENABLED': True,
        'SPIDER_MIDDLEWARES': {
            'scrapy_deltafetch.DeltaFetch': 120,
        },
        'ITEM_PIPELINES' : {
            'rental_crawlers.pipelines.CLPipeline': 300,
        }
    }

    '''
    Callback method for parsing the response text into a CLItem. 
    '''
    def parse_listings(self, response):
        item = CLItem()

        item['title'] = response.xpath('//span[@id="titletextonly"]/text()').extract_first()
        item['location'] = response.xpath('//small/text()').extract_first()
        item['sqft'] = response.xpath('//span[@class="housing"]/text()').extract_first()
        item['price'] = response.xpath('//span[@class="price"]/text()').extract_first()
        item['date'] = response.xpath('//time/@datetime').extract_first()
        item['lat'] = response.xpath('//div/@data-latitude').extract_first()
        item['long'] = response.xpath('//div/@data-longitude').extract_first()
        item['description'] = response.xpath('//section[@id="postingbody"]/text()').extract()
        item['url'] = response.url
        item['source'] = "Craigslist"
        yield item

#terminal: scrapy crawl [name] -o [filename]
