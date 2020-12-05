import scrapy
import datetime
import random
import time
from scrapy.crawler import CrawlerProcess
from scrapy.settings import default_settings
from rental_crawlers.spiders.kj_listings import KJSpider
from rental_crawlers.spiders.cl_listings import CLSpider
from rental_crawlers.spiders.v_listings import VSpider

time.sleep(random.randint(1,15)*60)

#Gets today's date and returns it in isoformat YYYY-MM-DD
month = datetime.date.today().strftime("%Y-%m")

# FEED_FORMAT is the output file type (accepts csv, json)
# FEED_URI is the name of the output file (if no path specified, will put in same folder as where script is)
process = CrawlerProcess({
    'USER_AGENT': default_settings.USER_AGENT,
    'FEED_FORMAT': 'csv',
    'FEED_URI': "../results/raw/listings-" + month + ".csv"
})

process.crawl(CLSpider)
process.crawl(KJSpider)
# Need Splash running for VSpider: docker run -p 8050:8050 -p 5023:5023 scrapinghub/splash
process.crawl(VSpider)
process.start()
