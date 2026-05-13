#!/usr/bin/env bash
# validate_step2.sh — verify the Dockerfile no longer contains a build-time
# yolo export, and that entrypoint.sh exists with the right shebang.
# Exits 0 if all checks pass, 1 otherwise.

set -e

echo "=== Step 2 validator: Dockerfile refactored ==="

# 1. Kiểm tra entrypoint.sh tồn tại và có quyền thực thi (executable)
[ -x entrypoint.sh ] || { 
    echo "FAIL: entrypoint.sh missing or not executable"
    exit 1 
}
echo "PASS: entrypoint.sh present + executable"

# 2. Kiểm tra entrypoint có đúng shebang yêu cầu không
head -1 entrypoint.sh | grep -q '^#!/usr/bin/env bash' \
    || { echo "FAIL: entrypoint.sh missing shebang"; exit 1; }
echo "PASS: shebang OK"

# 3. Kiểm tra Dockerfile.ci đã khai báo ENTRYPOINT trỏ đến file script chưa
grep -q 'ENTRYPOINT.*entrypoint.sh' Dockerfile.ci \
    || { echo "FAIL: Dockerfile.ci does not ENTRYPOINT entrypoint.sh"; exit 1; }
echo "PASS: Dockerfile.ci wires ENTRYPOINT"

# 4. Đảm bảo Dockerfile KHÔNG còn dòng lệnh RUN để biên dịch engine.
# Việc biên dịch lúc build sẽ thất bại trên GitHub Runner (do thiếu GPU).
if BAD=$(grep -nE "RUN.*format=['\"]?engine['\"]?" Dockerfile.ci); then
    echo "FAIL: Dockerfile.ci still has a RUN line that compiles the engine:"
    echo " $BAD"
    echo " Move that step into entrypoint.sh per Step 2.1."
    exit 1
fi

echo "PASS: no build-time engine compile in Dockerfile.ci"
echo "=== Step 2 PASS ==="
