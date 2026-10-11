import csv, json, os, datetime

with open("Helpers/config.json") as f:
    cfg = json.load(f)
total = cfg["total_sessions"]
warn = cfg["thresholds"]["warning"]
fail = cfg["thresholds"]["failure"]

with open("Helpers/assets.csv") as f:
    rows = list(csv.DictReader(f))

os.makedirs("reports", exist_ok=True)
now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
absent_lines = []
present_lines = []

for r in rows:
    ans = ""
    while ans not in ("p", "a"):
        ans = input(f"{r['Names']} - present (p) or absent (a)? ").strip().lower()
    if ans == "p":
        r["Attendance Count"] = str(int(r["Attendance Count"]) + 1)
        present_lines.append(f"{now} PRESENT {r['Names']}")
    else:
        r["Absence Count"] = str(int(r["Absence Count"]) + 1)
        absent_lines.append(f"{now} ABSENT {r['Names']}")
    pct = int(r["Attendance Count"]) / total * 100
    status = "FAILURE" if pct < fail else ("WARNING" if pct < warn else "OK")
    print(f"  {r['Names']}: {pct:.0f}% [{status}]")

with open("Helpers/assets.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["Email", "Names", "Attendance Count", "Absence Count"])
    w.writeheader()
    w.writerows(rows)

with open("reports/attendance.log", "a") as f:
    f.write("\n".join(present_lines + absent_lines) + "\n")
if absent_lines:
    with open("reports/absent.log", "a") as f:
        f.write("\n".join(absent_lines) + "\n")
print("Session saved.")
