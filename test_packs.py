import sys
sys.path.append('/home/akash/Desktop/IDP/content_engine')
import asyncio
from gateway_main import _canonical_pack_records
async def run():
    packs, cached, sources = await _canonical_pack_records()
    import json
    print(json.dumps(packs, indent=2))
asyncio.run(run())
