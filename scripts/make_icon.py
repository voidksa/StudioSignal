"""Generate the StudioSignal application icon."""
from pathlib import Path
import runpy
import shutil
root=Path(__file__).resolve().parent
runpy.run_path(str(root/'make_activity_icons.py'),run_name='__main__')
out=root.parent/'assets'
shutil.copyfile(out/'StudioSignal-logo.png',out/'StudioSignal-icon.png')
