"""Reproducible local browser tests using project Playwright + existing Chrome."""
import sys, os, json, argparse, re, math, shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'integration-apps/.deps'/('python-windows' if os.name=='nt' else 'python-linux')))
from playwright.sync_api import sync_playwright

def run(url,out):
    out.mkdir(parents=True,exist_ok=True)
    executable=os.getenv('TERMR_BROWSER_EXECUTABLE',r'C:\Program Files\Google\Chrome\Application\chrome.exe' if os.name=='nt' else shutil.which('chromium'))
    if not executable:raise RuntimeError('Set TERMR_BROWSER_EXECUTABLE to an installed Chrome/Chromium executable.')
    checks=[]; errors=[]; console_errors=[]; http_errors=[]
    with sync_playwright() as pw:
        browser=pw.chromium.launch(executable_path=executable,headless=True)
        page=browser.new_page(viewport={'width':1280,'height':900})
        page.on('pageerror',lambda error:errors.append(str(error)))
        page.on('console',lambda message:console_errors.append(message.text) if message.type=='error' else None)
        page.on('response',lambda response:http_errors.append(dict(status=response.status,url=response.url)) if response.status>=400 else None)
        page.goto(url)
        page.wait_for_function("document.getElementById('live')?.data?.length === 2")
        page.wait_for_function("document.querySelector('#ggplot img')?.naturalWidth > 0")
        assert page.locator('.shiny-output-error').count()==0
        page.evaluate("window.phaseEPlot = document.getElementById('live')")
        if 'EMPTY' in page.locator('#source_status').inner_text():
            page.locator('#empty').click();page.wait_for_function("!document.getElementById('source_status').innerText.includes('EMPTY')")
        text=page.locator('#source_status').inner_text()
        before=int(re.search(r'sequence:\s*(\d+)',text)[1])
        page.locator('#next_sample').click()
        page.wait_for_function('(n) => document.getElementById("source_status").innerText.includes("sequence: "+n+" |")',arg=before+1)
        page.wait_for_function('(n) => document.getElementById("live").data[0].customdata?.at(-1)?.endsWith(":"+n)',arg=before+1)
        sample=page.evaluate("({status:document.getElementById('source_status').innerText,traces:document.getElementById('live').data.map(t=>({x:t.x,y:t.y,ids:t.customdata}))})")
        source=re.search(r'Source:\s*(\w+)',sample['status'])[1]
        expected=40+(0 if source=='alpha' else 10)+12*math.sin((before+1)/3)
        assert abs(sample['traces'][0]['y'][-1]-expected)<1e-10
        checks.append(dict(case='reactive-update',status='PASS',expected=expected,actual=sample['traces'][0]['y'][-1]))
        page.locator('#source').click()
        new='beta' if source=='alpha' else 'alpha'
        page.wait_for_function('(s)=>document.getElementById("live").data[0].customdata?.at(-1)===s+":1"',arg=new)
        assert new in page.locator('#source_status').inner_text()
        checks.append(dict(case='source-reset',status='PASS'))
        page.locator('#empty').click()
        page.wait_for_function('document.getElementById("live").data.every(t=>t.y.length===0)')
        assert page.locator('#agreement').inner_text().startswith('0 rows')
        checks.append(dict(case='empty',status='PASS'))
        page.locator('#empty').click()
        page.wait_for_function('document.getElementById("live").data[0].y.length>0')
        page.locator('#invalid').click()
        page.wait_for_function('document.getElementById("live").data.every(t=>t.y.at(-1)===null)')
        checks.append(dict(case='NA-NaN-gap',status='PASS'))
        page.locator('#source').click()
        page.wait_for_function('document.getElementById("live").data[0].customdata?.at(-1)?.endsWith(":1")')
        # Capture a useful visual with several points; lines-only Plotly traces
        # intentionally have no segment when a source has just one sample.
        for sequence in range(2,7):
            page.locator('#next_sample').click()
            page.wait_for_function('(n)=>document.getElementById("live").data[0].customdata?.at(-1)?.endsWith(":"+n)',arg=sequence)
        assert '\u6771\u4eac' in page.locator('#source_status').inner_text(),page.locator('#source_status').inner_text()
        checks.append(dict(case='Unicode-source-label',status='PASS'))
        assert page.evaluate("document.getElementById('live') === window.phaseEPlot")
        assert page.locator('.shiny-output-error').count()==0
        assert not errors,errors
        assert not console_errors,console_errors
        assert not http_errors,http_errors
        page.screenshot(path=str(out/'analytics-browser.png'),full_page=True)
        checks.append(dict(case='stable-widget-and-ggplot',status='PASS'))
        version=browser.version
        page.close()
        for i in range(3):
            page=browser.new_page();page.goto(url);page.wait_for_selector('#source_status.shiny-text-output:not(.recalculating)');page.close()
        browser.close()
    result=dict(status='PASS',browser=version,checks=checks,page_errors=errors,
        console_errors=console_errors,http_errors=http_errors,closed_sessions=4)
    (out/'browser-results.json').write_text(json.dumps(result,indent=2))
    print(json.dumps(result))
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--url',required=True);parser.add_argument('--out',default='audit-results/real-world-apps/browser')
    args=parser.parse_args();run(args.url,ROOT/args.out)
