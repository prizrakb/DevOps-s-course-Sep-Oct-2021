"""
This script based on https://gist.github.com/stewartadam/f59f47614da1a9ab62d9881ae4fbe656
Edited by Juri Gogolev [2021-09-05 18:19] for Andersen DevOps courses (Sep-Oct 2021)
Hope u enjoy ;D
"""
import re
from urllib.parse import urlparse, urlunparse
from flask import Flask, render_template, request, abort, Response, redirect, json
import requests
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
CHUNK_SIZE = 1024
LOG = logging.getLogger("app.py")

@app.route('/', defaults={'url': ''}, methods=["GET", "POST"])
@app.route('/<path:url>', methods=["GET", "POST"])
def proxy(url):
    request_data = request.get_json(force=True, silent=True)
    url_parts = urlparse('%s://%s' % (request.scheme, url))
    r = make_request(url, request.method, dict(request.headers), request.form, request_data)
    LOG.debug("Got %s response from %s",r.status_code, url)
    headers = dict(r.raw.headers)
    def generate():
        for chunk in r.raw.stream(decode_content=False):
            yield chunk
    out = Response(generate(), headers=headers)
    out.status_code = r.status_code
    return out

def make_request(url, method, headers={}, data=None, json_inf={}):
#    url = 'http://127.0.0.1/%s' + url
    url = 'http://myvm.localhost/%s' % url
    referer = request.headers.get('referer')
    data_inf=json.dumps(json_inf, indent = 4) 
#    if referer:
#        proxy_ref = proxied_request_info(referer)
#        headers.update({ "referer" : "http://%s/%s" % (proxy_ref[0], proxy_ref[1])})

    LOG.debug("Sending %s %s with headers: %s and data %s", method, url, headers, data)
    print(data_inf)
    return requests.request(method, url, params=request.args, stream=True, headers=headers, allow_redirects=False, data=data_inf)

if __name__ == "__main__":
    app.run(debug=True,port=443,ssl_context=('cert.pem', 'key.pem'))
