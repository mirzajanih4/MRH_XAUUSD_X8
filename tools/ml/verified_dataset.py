from pathlib import Path
import os

# STEP137.10.1A - Read-only verified data foundation
common_dir = (
    Path(os.environ["APPDATA"])
    / "MetaQuotes"
    / "Terminal"
    / "Common"
    / "Files"
)

entry_file = common_dir / "MRH_X8_EntryLinks_v1.tsv"
outcome_file = common_dir / "MRH_X8_BrokerOutcomes_v1.tsv"

def count_records(path):
    if not path.is_file():
        return 0
    with path.open("r", encoding="utf-8", errors="replace") as file:
        return sum(1 for line in file if line.strip())

entry_count = count_records(entry_file)
outcome_count = count_records(outcome_file)

print("STEP137.10.1A - VERIFIED DATA FOUNDATION")
print(f"EntryRecords={entry_count}")
print(f"BrokerOutcomeRecords={outcome_count}")

if not entry_file.is_file():
    print("Status=WAITING_FOR_ENTRY_LINK")
elif not outcome_file.is_file():
    print("Status=WAITING_FOR_BROKER_OUTCOME")
else:
    print("Status=FILES_AVAILABLE_VALIDATION_PENDING")

print("TrainingAllowed=FALSE")
