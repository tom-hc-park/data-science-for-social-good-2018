# -*- coding: utf-8 -*-
from urllib.parse import urljoin, urlparse
from scrapy.spiders import CrawlSpider, Rule
from scrapy.linkextractors import LinkExtractor
from rental_crawlers.items import CLItem


class KJSpider(CrawlSpider):

    name = 'kj_listings'
    allowed_domains = ['kijiji.ca']
    start_urls = [
        'https://www.kijiji.ca/b-apartments-condos/delta-surrey-langley/c37l1700285',   #apartments/condos
        'https://www.kijiji.ca/b-house-rental/delta-surrey-langley/c43l1700285',        #house rentals
        'https://www.kijiji.ca/b-room-rental-roommate/delta-surrey-langley/c36l1700285' #room rentals
    ]

    '''
    Rules for automatically following the links to the listing, and going to the next listing.
    '''
    rules = (
        Rule(LinkExtractor(allow=(), restrict_xpaths=('//div/a[contains(@class,"title enable-search-navigation-flag")]')),
             process_links=True, callback='parse_listings', follow=True),
        Rule(LinkExtractor(allow=(), restrict_xpaths=('//a[@title="Next"]')),
             process_links=True, follow=True),
    )

    custom_settings = {
        'LOG_LEVEL': 'INFO',
        'DELTAFETCH_ENABLED': True,
        'SPIDER_MIDDLEWARES': {
            'scrapy_deltafetch.DeltaFetch': 120,
        },
        'ITEM_PIPELINES' : {
            'rental_crawlers.pipelines.KJPipeline': 400,
        }
    }

    '''
    Callback method for parsing the response text into a CLItem.
    description xpath is correct but may not be needed for KJ since most useful information is extracted from
     other fields.
    '''
    def parse_listings(self, response):
        # if ".ca" in response.url:
        #     from scrapy.shell import inspect_response
        #     inspect_response(response, self)

        item = CLItem()
        try:
            item['title'] = response.xpath('//div/h1[starts-with(@class,"title-")]/text()').extract_first()
            # This filters out the "Housing Wanted" ads.
            if "Wanted" in item['title']:
                return
            else:
                item['location'] = response.xpath('//span[contains(@class, "address")]/text()').extract_first()
                item['price'] = response.xpath('//span[contains(@class, "currentPrice")]/span/text()').extract_first()
                item['date'] = response.xpath('//div[contains(@class, "datePosted")]/time/@datetime').extract_first()
                #Description is correct but we may not need it for KJ.
                item['description'] = response.xpath('//div[contains(@class, "descriptionContainer")]/div/p').extract()
                item['url'] = response.xpath('//link[contains(@href, "kijiji.ca/v")]/@href').extract_first()
                item['source'] = "Kijiji"
                yield item
        except TypeError:
            return

    def process_links(self, links):
        for link in links:
            link.url = urlparse.urljoin('https://www.kijiji.ca/', link.url)

        return links

#terminal: scrapy crawl [name] -o [filename]
