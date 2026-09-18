import sys,json,io,urllib.parse,unittest.mock
sys.path.insert(0,'tool');import prepare_transit_reference_grid as grid
rows=json.load(open(grid.ROOT/'reference-grid.json'));stored={};post_count=0;fail=True
class Response(io.BytesIO):
 def __enter__(self):return self
 def __exit__(self,*args):self.close()
def http(request,timeout):
 global post_count,fail
 if request.get_method()=='POST':
  post_count+=1
  if fail and post_count==2:raise OSError('Controlled upload interruption')
  for row in json.loads(request.data):stored[row['grid_id']]=row
  return Response(b'')
 query=urllib.parse.parse_qs(urllib.parse.urlsplit(request.full_url).query)
 start=int(query['offset'][0]);page=sorted(stored.values(),key=lambda row:row['grid_id'])[start:start+1000]
 return Response(json.dumps(page).encode())
with unittest.mock.patch.object(grid,'read_values',return_value={'SUPABASE_URL':'https://example.invalid','SUPABASE_SECRET_KEY':'dummy'}),unittest.mock.patch.object(grid.urllib.request,'urlopen',http):
 try:grid.apply('official-2026-09-17','2026-09-17')
 except RuntimeError:pass
 assert len(stored)==400
 print('Interrupted after 400 rows; partial staging retained')
 fail=False;grid.apply('official-2026-09-17','2026-09-17');assert len(stored)==len(rows)
 print('Resume verified prior rows and completed all 9641 identities: PASS')
 first=next(iter(stored));stored[first]={**stored[first],'unique_route_count':-1}
 try:grid.apply('official-2026-09-17','2026-09-17')
 except RuntimeError:print('Mismatched existing immutable row rejected: PASS')
 else:raise AssertionError('Mismatched row accepted')
