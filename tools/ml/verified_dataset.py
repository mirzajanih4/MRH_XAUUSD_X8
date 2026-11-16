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

# STEP137.10.1B - Validate broker outcome records
from decimal import Decimal, InvalidOperation

valid_outcomes = {}
rejected_outcomes = 0

if outcome_file.is_file():
    with outcome_file.open("r", encoding="utf-8-sig") as source:
        for raw in source:
            if not raw.strip():
                continue

            fields = raw.rstrip("\r\n").split("\t")
            if len(fields) != 3:
                rejected_outcomes += 1
                continue

            identity, currency, pnl_text = fields
            identity_parts = identity.split("|")

            try:
                pnl = Decimal(pnl_text)
                valid_identity = (
                    len(identity_parts) == 5
                    and all(identity_parts)
                    and identity_parts[1].isdigit()
                    and identity_parts[2].isdigit()
                    and identity_parts[4].isdigit()
                )

                if (
                    not valid_identity
                    or not currency.strip()
                    or not pnl.is_finite()
                    or identity in valid_outcomes
                ):
                    raise ValueError("Invalid outcome record")

            except (InvalidOperation, ValueError):
                rejected_outcomes += 1
                continue

            valid_outcomes[identity] = (currency, pnl)

print(f"ValidOutcomeRecords={len(valid_outcomes)}")
print(f"RejectedOutcomeRecords={rejected_outcomes}")

# STEP137.10.1C - Verified entry/outcome join
valid_entries = {}
rejected_entries = 0

if entry_file.is_file():
    with entry_file.open("r", encoding="utf-8-sig") as source:
        for raw in source:
            if not raw.strip():
                continue

            fields = raw.rstrip("\r\n").split("\t")

            try:
                if len(fields) != 12:
                    raise ValueError("Invalid entry schema")

                identity = fields[0]
                deal_id = int(fields[1])
                entry_time = int(fields[2])
                bos_time = int(fields[6])
                swing_time = int(fields[9])

                entry_price = Decimal(fields[3])
                volume = Decimal(fields[4])
                broken_level = Decimal(fields[8])
                permission = Decimal(fields[10])
                stop_loss = Decimal(fields[11])

                values = (
                    entry_price, volume, broken_level,
                    permission, stop_loss
                )

                if (
                    len(identity.split("|")) != 5
                    or not all(identity.split("|"))
                    or identity in valid_entries
                    or deal_id <= 0
                    or not (0 < swing_time <= bos_time <= entry_time)
                    or not all(value.is_finite() for value in values)
                    or any(value <= 0 for value in values)
                    or entry_price == stop_loss
                ):
                    raise ValueError("Invalid entry record")

            except (ValueError, InvalidOperation):
                rejected_entries += 1
                continue

            valid_entries[identity] = fields

joined_ids = valid_entries.keys() & valid_outcomes.keys()

print(f"ValidEntryRecords={len(valid_entries)}")
print(f"RejectedEntryRecords={rejected_entries}")
print(f"VerifiedJoinedRecords={len(joined_ids)}")
print("MLTrainingStatus=BLOCKED_PENDING_DATA_VALIDATION")
