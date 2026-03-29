#!/bin/bash
set -e
echo “Setting up VoiceForge API proxy…”

mkdir -p /root/mysite/proxy /root/mysite/uploads/temp

python3 << ‘PYEOF’
import os

os.makedirs(’/root/mysite/proxy’, exist_ok=True)

# Write proxy.py

with open(’/root/mysite/proxy/proxy.py’, ‘w’) as f:
f.write(”””#!/usr/bin/env python3
import os,json,uuid,time,threading,base64,urllib.parse
from http.server import HTTPServer,BaseHTTPRequestHandler
from urllib.request import urlopen,Request

PORT=8181
XAI_KEY=os.environ.get(‘XAI_API_KEY’,’’)
ANTHROPIC_KEY=os.environ.get(‘ANTHROPIC_API_KEY’,’’)
PROXY_TOKEN=os.environ.get(‘PROXY_TOKEN’,’’)
PUBLIC_BASE=os.environ.get(‘PUBLIC_BASE’,‘https://www.davidjamesblack.com’)
UPLOAD_DIR=’/uploads/temp’
os.makedirs(UPLOAD_DIR,exist_ok=True)

def cleanup():
while True:
now=time.time()
try:
for f in os.listdir(UPLOAD_DIR):
p=os.path.join(UPLOAD_DIR,f)
if os.path.isfile(p) and now-os.path.getmtime(p)>300:
os.remove(p)
except:pass
time.sleep(60)
threading.Thread(target=cleanup,daemon=True).start()

class H(BaseHTTPRequestHandler):
def log_message(self,f,*a):pass
def j(self,c,d):
b=json.dumps(d).encode()
self.send_response(c)
self.send_header(‘Content-Type’,‘application/json’)
self.send_header(‘Content-Length’,len(b))
self.send_header(‘Access-Control-Allow-Origin’,’*’)
self.end_headers()
self.wfile.write(b)
def auth(self):
if PROXY_TOKEN and self.headers.get(‘X-Proxy-Token’,’’)!=PROXY_TOKEN:
self.j(401,{‘error’:‘Unauthorized’});return False
return True
def do_OPTIONS(self):
self.send_response(200)
self.send_header(‘Access-Control-Allow-Origin’,’*’)
self.send_header(‘Access-Control-Allow-Methods’,‘POST,OPTIONS’)
self.send_header(‘Access-Control-Allow-Headers’,‘Content-Type,X-Proxy-Token’)
self.end_headers()
def body(self):
return self.rfile.read(int(self.headers.get(‘Content-Length’,0)))
def do_POST(self):
p=urllib.parse.urlparse(self.path).path
if p==’/api/upload-face’:self.upload()
elif p==’/api/imagine’:self.imagine()
elif p==’/api/claude’:self.claude()
else:self.j(404,{‘error’:‘not found’})
def upload(self):
if not self.auth():return
try:
d=json.loads(self.body())
img=d.get(‘image’,’’)
if ‘,’ not in img:self.j(400,{‘error’:‘bad image’});return
h,b64=img.split(’,’,1)
ext=‘jpg’ if ‘jpeg’ in h or ‘jpg’ in h else ‘png’
fn=uuid.uuid4().hex+’.’+ext
open(os.path.join(UPLOAD_DIR,fn),‘wb’).write(base64.b64decode(b64))
self.j(200,{‘url’:f’{PUBLIC_BASE}/uploads/temp/{fn}’})
except Exception as e:self.j(500,{‘error’:str(e)})
def imagine(self):
if not self.auth():return
if not XAI_KEY:self.j(500,{‘error’:‘no xai key’});return
try:
d=json.loads(self.body())
payload={
‘model’:‘grok-2-image’,
‘prompt’:d.get(‘prompt’,’’),
‘images’:[{‘type’:‘image_url’,‘url’:u} for u in d.get(‘images’,[])],
‘n’:min(int(d.get(‘n’,3)),3),
‘aspect_ratio’:‘1:1’
}
req=Request(‘https://api.x.ai/v1/images/edits’,
data=json.dumps(payload).encode(),
headers={‘Content-Type’:‘application/json’,‘Authorization’:f’Bearer {XAI_KEY}’},
method=‘POST’)
with urlopen(req,timeout=90) as r:result=json.loads(r.read())
self.j(200,{‘images’:[i.get(‘url’,’’) for i in result.get(‘data’,[])]})
except Exception as e:self.j(500,{‘error’:str(e)})
def claude(self):
if not self.auth():return
if not ANTHROPIC_KEY:self.j(500,{‘error’:‘no anthropic key’});return
try:
b=self.body()
req=Request(‘https://api.anthropic.com/v1/messages’,data=b,
headers={‘Content-Type’:‘application/json’,‘x-api-key’:ANTHROPIC_KEY,‘anthropic-version’:‘2023-06-01’},
method=‘POST’)
with urlopen(req,timeout=60) as r:result=r.read()
self.send_response(200)
self.send_header(‘Content-Type’,‘application/json’)
self.send_header(‘Access-Control-Allow-Origin’,’*’)
self.end_headers()
self.wfile.write(result)
except Exception as e:self.j(500,{‘error’:str(e)})

HTTPServer((‘0.0.0.0’,PORT),H).serve_forever()
“””)

# Write Dockerfile

with open(’/root/mysite/proxy/Dockerfile’, ‘w’) as f:
f.write(“FROM python:3.12-slim\nWORKDIR /app\nCOPY proxy.py .\nCMD ["python","-u","proxy.py"]\n”)

# Write docker-compose.yml

with open(’/root/mysite/docker-compose.yml’, ‘w’) as f:
f.write(””“services:
mysite:
image: nginx:alpine
volumes:
- ./html:/usr/share/nginx/html
- ./uploads:/usr/share/nginx/html/uploads
ports:
- “8080:80”
labels:
- “traefik.enable=true”
- “traefik.http.routers.mysite.rule=Host(`davidjamesblack.com`) || Host(`www.davidjamesblack.com`)”
- “traefik.http.routers.mysite.entrypoints=websecure”
- “traefik.http.routers.mysite.tls.certresolver=letsencrypt”
- “traefik.http.services.mysite.loadbalancer.server.port=80”
api-proxy:
build: ./proxy
restart: unless-stopped
env_file:
- .env
volumes:
- ./uploads:/uploads
labels:
- “traefik.enable=true”
- “traefik.http.routers.api-proxy.rule=(Host(`davidjamesblack.com`) || Host(`www.davidjamesblack.com`)) && PathPrefix(`/api/`)”
- “traefik.http.routers.api-proxy.entrypoints=websecure”
- “traefik.http.routers.api-proxy.tls.certresolver=letsencrypt”
- “traefik.http.routers.api-proxy.priority=10”
- “traefik.http.services.api-proxy.loadbalancer.server.port=8181”
“””)

print(“All files written successfully”)
PYEOF

echo “Done. Now create /root/mysite/.env with your keys, then run: cd /root/mysite && docker compose up -d –build”