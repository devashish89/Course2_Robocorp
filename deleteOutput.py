import shutil
import os
def delete_output_dir():
    if os.path.isdir('output'):
        shutil.rmtree('output')
