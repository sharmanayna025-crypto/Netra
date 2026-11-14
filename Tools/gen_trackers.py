import json, collections

categories = {
 "advertising": {"title":"Advertising","risk":"high","symbol":"megaphone.fill",
   "summary":"Builds a profile of your interests so advertisers can target you, often across many sites.",
   "advice":"Turn on Safari's “Hide IP Address from Trackers” and review ad personalisation in the services you use."},
 "social": {"title":"Social","risk":"medium","symbol":"person.2.fill",
   "summary":"Lets a social network see which pages you visit, even if you never tap its buttons.",
   "advice":"Log out of social accounts while browsing, and keep Safari's cross-site tracking prevention on."},
 "analytics": {"title":"Analytics","risk":"low","symbol":"chart.bar.fill",
   "summary":"Counts visits and measures how people use the site. Usually the least invasive kind of tracking.",
   "advice":"Generally low risk. A content blocker can remove it if you prefer."},
 "session_replay": {"title":"Session replay","risk":"high","symbol":"record.circle.fill",
   "summary":"Records taps, scrolls and sometimes what you type so the site can replay your visit.",
   "advice":"Avoid entering sensitive details on sites that record sessions."},
 "fingerprinting": {"title":"Fingerprinting","risk":"high","symbol":"touchid",
   "summary":"Identifies your device from its traits (screen, fonts, hardware) without needing cookies.",
   "advice":"Keep Safari's advanced fingerprinting protection on; it limits what these scripts can read."},
}

def C(id, name, summary, trackers, owns=None):
    return {"id":id,"name":name,"summary":summary,"owns":owns or [],
            "trackers":[{"domain":d,"category":c,**({"what":w} if w else {})} for (d,c,w) in trackers]}

companies = [
 C("google","Google","Runs the largest ad and analytics network on the web, so it can link your visits across a huge number of sites.",
   [("google-analytics.com","analytics","Counts visits and records how you move through a site."),
    ("googletagmanager.com","analytics","Loads other tracking scripts on the site's behalf."),
    ("doubleclick.net","advertising","Google's ad-serving network, used to target and measure ads."),
    ("googlesyndication.com","advertising","Serves Google AdSense ads."),
    ("googleadservices.com","advertising","Measures whether ad clicks lead to purchases."),
    ("googletagservices.com","advertising","Loads Google ad tags."),
    ("app-measurement.com","analytics","Firebase analytics used by apps and some sites.")],
   ["google.com","youtube.com","blogger.com","blogspot.com","google.co.in","gmail.com","withgoogle.com"]),
 C("meta","Meta","Owns Facebook, Instagram and WhatsApp; its pixel can tell Meta about your visits even if you have no account.",
   [("facebook.net","social","Facebook SDK and Pixel scripts."),
    ("facebook.com","social","Facebook plugins and the tracking pixel.")],
   ["facebook.com","instagram.com","whatsapp.com","messenger.com","fb.com","facebook.net","meta.com"]),
 C("microsoft","Microsoft","Operates Clarity (session recording) and Microsoft Advertising conversion tracking.",
   [("clarity.ms","session_replay","Microsoft Clarity records sessions and heatmaps."),
    ("bat.bing.com","advertising","Microsoft Advertising conversion tracking.")],
   ["microsoft.com","bing.com","live.com","office.com","msn.com","clarity.ms","skype.com","xbox.com","github.com"]),
 C("linkedin","LinkedIn","Its Insight Tag links your visits to your professional profile for ad targeting.",
   [("snap.licdn.com","advertising","LinkedIn Insight Tag."),
    ("px.ads.linkedin.com","advertising","LinkedIn ad conversion pixel."),
    ("ads.linkedin.com","advertising","LinkedIn advertising."),
    ("linkedin.com","social","LinkedIn plugins and share buttons.")],
   ["linkedin.com","licdn.com"]),
 C("x","X (Twitter)","Ad pixels and embedded posts can report your visit back to X.",
   [("static.ads-twitter.com","advertising","X ad pixel."),
    ("ads-twitter.com","advertising","X advertising."),
    ("analytics.twitter.com","advertising","X conversion tracking."),
    ("platform.twitter.com","social","Embedded posts and share buttons.")],
   ["twitter.com","x.com","t.co"]),
 C("tiktok","TikTok","The TikTok pixel measures ads and builds interest profiles.",
   [("analytics.tiktok.com","advertising","TikTok pixel."),("tiktok.com","social","TikTok embeds and plugins.")],
   ["tiktok.com","tiktokv.com","bytedance.com"]),
 C("pinterest","Pinterest","Pinterest's tag tracks visits and purchases for ad targeting.",
   [("ct.pinterest.com","advertising","Pinterest conversion tag."),("pinterest.com","social","Pin buttons and widgets.")],
   ["pinterest.com"]),
 C("snap","Snap","Snap's pixel reports visits and purchases to Snapchat advertising.",
   [("sc-static.net","advertising","Snap pixel script."),("tr.snapchat.com","advertising","Snap conversion tracking.")],
   ["snapchat.com"]),
 C("amazon","Amazon","Amazon's ad system follows shopping and browsing interests across sites.",
   [("amazon-adsystem.com","advertising","Amazon advertising network.")],
   ["amazon.com","amazon.in","amazon.co.uk","amazon.de"]),
 C("adobe","Adobe","Adobe Analytics and Audience Manager track behaviour and build audience segments.",
   [("omtrdc.net","analytics","Adobe Analytics data collection."),("2o7.net","analytics","Adobe Analytics (legacy domain)."),
    ("adobedtm.com","analytics","Adobe's tag manager."),("demdex.net","advertising","Adobe Audience Manager cross-site ID."),
    ("everesttech.net","advertising","Adobe advertising cloud.")],
   ["adobe.com"]),
 C("oracle","Oracle","Oracle's BlueKai sells audience data used to target ads.",
   [("bluekai.com","advertising","Oracle data marketplace tracking.")],["oracle.com"]),
 C("thetradedesk","The Trade Desk","An ad-buying platform that tracks you across sites to bid on ads.",
   [("adsrvr.org","advertising","Ad bidding and cross-site ID.")],["thetradedesk.com"]),
 C("xandr","Xandr (Microsoft)","An ad exchange that matches your visit to bids from advertisers.",
   [("adnxs.com","advertising","Ad exchange and user matching.")],["xandr.com","appnexus.com"]),
 C("criteo","Criteo","Retargeting: follows you to show ads for products you looked at.",
   [("criteo.com","advertising","Retargeting ads."),("criteo.net","advertising","Retargeting ads.")],["criteo.com"]),
 C("taboola","Taboola","Recommends sponsored content based on your browsing.",[("taboola.com","advertising","Content recommendation ads.")],["taboola.com"]),
 C("outbrain","Outbrain","Recommends sponsored content based on your browsing.",[("outbrain.com","advertising","Content recommendation ads.")],["outbrain.com"]),
 C("quantcast","Quantcast","Audience measurement and ad targeting.",[("quantserve.com","advertising","Audience measurement pixel.")],["quantcast.com"]),
 C("lotame","Lotame","A data exchange that builds audience profiles.",[("crwdcntrl.net","advertising","Audience data collection.")],["lotame.com"]),
 C("liveramp","LiveRamp","Connects your identity across devices and data sets for advertisers.",[("rlcdn.com","advertising","Identity resolution.")],["liveramp.com"]),
 C("magnite","Magnite","A programmatic ad exchange.",[("rubiconproject.com","advertising","Ad exchange.")],["magnite.com","rubiconproject.com"]),
 C("pubmatic","PubMatic","A programmatic ad exchange.",[("pubmatic.com","advertising","Ad exchange.")],["pubmatic.com"]),
 C("openx","OpenX","A programmatic ad exchange.",[("openx.net","advertising","Ad exchange.")],["openx.com"]),
 C("indexexchange","Index Exchange","A programmatic ad exchange.",[("casalemedia.com","advertising","Ad exchange.")],["indexexchange.com"]),
 C("comscore","Comscore","Audience measurement that follows panel and site traffic.",[("scorecardresearch.com","analytics","Audience measurement.")],["comscore.com"]),
 C("hotjar","Hotjar","Records sessions and heatmaps of taps and scrolls.",
   [("hotjar.com","session_replay","Session recordings and heatmaps."),("hotjar.io","session_replay","Session recordings and heatmaps.")],["hotjar.com"]),
 C("fullstory","FullStory","Records full sessions so the site can replay what you did.",[("fullstory.com","session_replay","Session replay.")],["fullstory.com"]),
 C("mouseflow","Mouseflow","Records sessions and heatmaps.",[("mouseflow.com","session_replay","Session replay and heatmaps.")],["mouseflow.com"]),
 C("luckyorange","Lucky Orange","Records sessions and live chat visitors.",
   [("luckyorange.com","session_replay","Session replay."),("luckyorange.net","session_replay","Session replay.")],["luckyorange.com"]),
 C("logrocket","LogRocket","Records sessions for debugging, including page content.",
   [("logrocket.com","session_replay","Session replay."),("lr-ingest.io","session_replay","Session replay data.")],["logrocket.com"]),
 C("smartlook","Smartlook","Records sessions and events.",[("smartlook.com","session_replay","Session replay.")],["smartlook.com"]),
 C("crazyegg","Crazy Egg","Heatmaps and recordings of clicks and scrolls.",[("crazyegg.com","session_replay","Heatmaps and recordings.")],["crazyegg.com"]),
 C("mixpanel","Mixpanel","Product analytics that tracks individual user actions.",[("mixpanel.com","analytics","Event analytics.")],["mixpanel.com"]),
 C("segment","Segment","Collects behaviour and forwards it to many other services.",
   [("segment.io","analytics","Data collection hub."),("segment.com","analytics","Data collection hub.")],["segment.com"]),
 C("amplitude","Amplitude","Product analytics that tracks individual user actions.",[("amplitude.com","analytics","Event analytics.")],["amplitude.com"]),
 C("heap","Heap","Automatically captures every click and tap.",[("heapanalytics.com","analytics","Auto-capture analytics.")],["heap.io"]),
 C("hubspot","HubSpot","Marketing analytics that ties visits to contacts.",
   [("hs-analytics.net","analytics","Visitor tracking."),("hs-scripts.com","analytics","HubSpot tracking loader."),("hsadspixel.net","advertising","HubSpot ad pixel.")],["hubspot.com"]),
 C("yandex","Yandex","Yandex Metrica analytics with session replay features.",[("mc.yandex.ru","analytics","Yandex Metrica."),("metrica.yandex.com","analytics","Yandex Metrica.")],["yandex.ru","yandex.com"]),
 C("chartbeat","Chartbeat","Real-time reading analytics for publishers.",[("chartbeat.com","analytics","Reader analytics.")],["chartbeat.com"]),
 C("optimizely","Optimizely","A/B testing that tracks how you respond to variants.",[("optimizely.com","analytics","Experiment tracking.")],["optimizely.com"]),
 C("cloudflare","Cloudflare","Privacy-friendlier web analytics from the site's CDN.",[("cloudflareinsights.com","analytics","Web analytics.")],["cloudflare.com"]),
 C("sharethis","ShareThis","Share buttons that also collect browsing data.",[("sharethis.com","social","Share buttons and tracking.")],["sharethis.com"]),
 C("fingerprint","Fingerprint","Identifies devices from hardware and browser traits for fraud and tracking.",
   [("fingerprint.com","fingerprinting","Device fingerprinting."),("fpjs.io","fingerprinting","Device fingerprinting.")],["fingerprint.com"]),
]

db = {
 "version": 1,
 "updated": "2026-11-12",
 "scoring": {
   "base": 100,
   "categoryPenalty": {"advertising":10,"social":8,"analytics":4,"session_replay":12,"fingerprinting":12},
   "bands": [{"min":90,"label":"Excellent"},{"min":75,"label":"Good"},{"min":50,"label":"Needs Attention"},{"min":0,"label":"At Risk"}],
 },
 "categories": categories,
 "companies": companies,
}

# validation
seen = collections.Counter()
ids = collections.Counter()
for c in companies:
    ids[c["id"]] += 1
    for t in c["trackers"]:
        seen[t["domain"]] += 1
        assert t["category"] in categories, t
assert all(v==1 for v in ids.values()), [k for k,v in ids.items() if v>1]
dups = [k for k,v in seen.items() if v>1]
assert not dups, dups
assert set(db["scoring"]["categoryPenalty"]) == set(categories)
with open("trackers.json","w") as f:
    json.dump(db, f, indent=1, ensure_ascii=False)
print(len(companies), "companies,", sum(seen.values()), "tracker domains")
