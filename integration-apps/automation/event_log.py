"""Bounded reading of an append-only journal across Windows/WSL DrvFS."""
import errno,json,time
READ_RETRIES=[]

def read_events(path):
    if not path.exists():return []
    for attempt in range(5):
        try:
            text=path.read_text(encoding='utf-8',errors='strict')
            break
        except OSError as error:
            if error.errno not in {errno.EAGAIN,errno.ENODATA,errno.ESTALE} or attempt==4:raise
            READ_RETRIES.append(dict(path=str(path),errno=error.errno,attempt=attempt+1))
            time.sleep(.01)
    result=[]
    for line in text.splitlines():
        try:result.append(json.loads(line))
        except json.JSONDecodeError:pass # Concurrent writer's incomplete last record.
    return result
