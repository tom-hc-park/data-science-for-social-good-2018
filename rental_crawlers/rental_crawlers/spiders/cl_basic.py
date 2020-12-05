# -*- coding: utf-8 -*-
import scrapy


class HousingSpider(scrapy.Spider):
    name = 'cl_basic'
    allowed_domains = ['vancouver.craigslist.ca']
    # TODO - generalize the start_urls
    start_urls = ['https://vancouver.craigslist.ca/search/rds/apa',
                  #                  'https://vancouver.craigslist.ca/search/rds/apa?s=120',
                  'https://vancouver.craigslist.ca/search/rds/apa?s=240']
    custom_settings = {
        'LOG_LEVEL': 'INFO'
    }

    def parse(self, response):
        # This gives us all of the titles / locations of the ads for a Craigslist page
        #        titles = response.xpath('//a[@class="result-title hdrlnk"]/text()').extract()
        #        locations = response.xpath('//span[@class="result-hood"]/text()').extract()

        listings = response.xpath('//p[@class="result-info"]')
        for listing in listings:
            title = listing.xpath('a/text()').extract_first()
            location = listing.xpath('span[@class="result-meta"]/span[@class="result-hood"]/text()').extract_first()
            housing_type = listing.xpath(
                'normalize-space(span[@class="result-meta"]/span[@class="housing"]/text())').extract_first().strip()
            price = listing.xpath('span[@class="result-meta"]/span[@class="result-price"]/text()').extract_first()
            date = listing.xpath('time/@datetime').extract_first()
            yield {'Title': title, 'Location': location, 'Housing': housing_type, 'Price': price, 'Date Posted': date}

# terminal: scrapy crawl housing -o [filename]
