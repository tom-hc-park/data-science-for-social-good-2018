# -*- coding: utf-8 -*-
from urllib.parse import urljoin
from scrapy.spiders import CrawlSpider, Rule
from scrapy.linkextractors import LinkExtractor
from rental_crawlers.items import CLItem
from scrapy_splash import SplashRequest
import json

class VSpider(CrawlSpider):

    name = 'v_listings'
    allowed_domains = ['vrbo.com']
    start_urls = [
        'https://www.vrbo.com/results?q=Surrey%2C%20BC%2C%20Canada'
    ]

    rules = (
        Rule(LinkExtractor(allow=(), restrict_xpaths=('//div[@class="rate"]')),
             process_request='start_requests', callback='parse_listings', follow=True),
        # Rule(LinkExtractor(allow=(), restrict_xpaths=('//a[contains(@href,"result")]')),
        #      process_request='start_requests', follow=True),
    )
# response.xpath('//div[@class="rate"]/a/@href').extract()
# response.xpath('//a[contains(@href,"result")]/@href').extract_first()

    custom_settings = {
        'LOG_LEVEL': 'INFO',
        'DELTAFETCH_ENABLED': True,
        'SPIDER_MIDDLEWARES': {
            'scrapy_deltafetch.DeltaFetch': 120,
        }

    }

    '''
    Get a SplashRequest from the start_urls, pass it to process_links to get the listing links on the page. 
    Also manually get first 9 pages of listings in the for loop 
    '''
    def start_requests(self):
        for url in self.start_urls:
            for i in range(8):
                nextPage = url+"&page="+str(i+2)
                yield SplashRequest(
                    nextPage, self.process_links,
                    args={'wait': 0.5}
                )

    # def parse(self,response):
    #     self.html_file = open("test2.html", 'w')
    #     self.html_file.write(response.text)
    #     self.html_file.close()

    '''
    Get all of the links to listings on a single result page and join the URLs to the correct base. 
    Generate a SplashRequest to get the response, pass it to parse_listings.
    '''
    def process_links(self, response):
        links = response.xpath('//div[@class="rate"]/a/@href').extract()
        for link in links:
            linkurl = urljoin('https://www.vrbo.com', link)
            yield SplashRequest(linkurl, self.parse_listings)

    '''
    Get the listing information from the response. 
    '''
    def parse_listings(self, response):
        json_string = response.xpath('//script[contains(.,"window.__INITIAL_STATE__")]/text()').extract_first()
        json_string = json_string.strip().strip("window.__INITIAL_STATE__ =")
        json_string = json_string.rstrip(";")
        parsed_json = json.loads(json_string)

        item = CLItem()

        item['title'] = parsed_json['listingReducer']['headline']
        item['rooms'] = str(parsed_json['listingReducer']['bedrooms']) + " bedroom"
        try:
            item['sqft'] = str(parsed_json['listingReducer']['area']) + parsed_json['listingReducer']['areaUnits']
        except KeyError:
            item['sqft'] = None
        item['price'] = parsed_json['listingReducer']['averagePrice']['localized']
        item['lat']= parsed_json['listingReducer']['geoCode']['latitude']
        item['long'] = parsed_json['listingReducer']['geoCode']['longitude']
        item['description'] = parsed_json['listingReducer']['description']
        item['address'] = None
        item['city'] = parsed_json['listingReducer']['address']['city']
        item['province'] = parsed_json['listingReducer']['address']['stateProvince']
        item['country'] = parsed_json['listingReducer']['address']['country']
        item['source'] = "VRBO"
        yield item