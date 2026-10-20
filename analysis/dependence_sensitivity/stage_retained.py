"""Copy the committed sensitivity inputs/results into the ignored working folder."""
import shutil
from paths import DATA, RETAINED, WORK

def stage():
    if WORK == RETAINED or WORK == DATA or RETAINED in WORK.parents or DATA in WORK.parents:
        raise ValueError("Choose an output directory outside the committed inputs and results")
    for source in (DATA, RETAINED):
        for file in source.iterdir():
            if file.is_file() and file.suffix in {'.npz', '.csv', '.json', '.txt'}:
                shutil.copy2(file, WORK / file.name)
    return WORK

if __name__ == '__main__':
    print(stage())
