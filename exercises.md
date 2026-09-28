# Phiếu Phản Ánh — K4 Level 3A, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng placeholder dưới mỗi câu bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Trần Kiên  Mã học viên: 2A202602571

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Quên set `AGENT_API_KEY` trên Railway: nếu có mặc định `"changeme"`, app vẫn chạy và ai đoán được `changeme` là gọi `/ask` miễn phí bằng tiền của mình mà không ai biết. Không có mặc định thì deploy fail ngay với `ValidationError` trong log → phát hiện và sửa trước khi có traffic.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-28T09:07:29.127131+00:00", "user_id": "sv01", "tokens_in": 3, "tokens_out": 37, "cost_usd": 2.265e-05}`
>
> (1) Lọc/đếm theo trường, ví dụ mọi request của `user_id=sv01` hoặc chỉ `level=error`. (2) Tính tổng/cảnh báo trên số liệu, ví dụ cộng `cost_usd` theo ngày và báo động khi vượt ngưỡng.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ... MB |
| Multi-stage | ... MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Phần chênh lệch là thứ bản 1 stage mang theo mà runtime không cần: base `python:3.11` đầy đủ (compiler, header, công cụ build ~ hàng trăm MB), cache của pip, và toàn bộ build context (`.git`, `.venv`, tests...) do `COPY . .` khi chưa có `.dockerignore`.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Dùng lại cache: `FROM`, tạo user, `COPY requirements.txt`, `RUN pip install`, `COPY --from=builder`. Chạy lại: chỉ `COPY app ./app` và các layer sau nó (vài giây). Nếu `COPY . .` đứng trước `pip install` thì sửa 1 ký tự cũng làm hỏng cache từ đó → cài lại toàn bộ thư viện mỗi lần build.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Lỗ hổng trong code (RCE, path traversal...) → kẻ tấn công chạy lệnh với quyền của process → process là root trong container → root trong container trùng UID 0 với host, kết hợp một lỗi thoát container/volume mount/docker socket là thành root trên host. `USER appuser` (UID 10001) cắt ở bước thứ 2: lệnh chỉ chạy với quyền user thường, không ghi được file hệ thống, thoát ra ngoài cũng chỉ là user không đặc quyền.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request: gửi 10 request lúc 10:00:59 (cuối phút cũ) và 10 request lúc 10:01:00–01 (bộ đếm vừa reset). Sliding window đếm 60 giây gần nhất nên lúc 10:01:01 vẫn thấy 10 request trước đó → chặn.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn **số request**/thời gian; cost guard giới hạn **số tiền**/tháng.
> - Rate limit cho qua, cost guard chặn: user gửi 5 request/phút (dưới hạn 10) nhưng mỗi request prompt rất dài, cả tháng cộng dồn vượt 10 USD → 402.
> - Rate limit chặn, cost guard cho qua: script spam 50 câu "hi" trong 1 phút, chi phí gần 0 nhưng từ request thứ 11 bị 429.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> 1. Redis mất kết nối → endpoint gộp trả 503 trên cả 3 container. 2. Orchestrator coi là liveness fail → restart cả 3 container cùng lúc. 3. Trong lúc restart, không instance nào nhận request → sập toàn bộ dịch vụ (kể cả request không cần Redis). 4. Redis về nhưng container còn đang khởi động/restart lặp → sự cố 30 giây thành vài phút. Tách ra thì `/health` vẫn 200 (không restart), chỉ `/ready` 503 → LB tạm ngừng gửi traffic, Redis về là phục vụ lại ngay.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Với Redis, `history_length` tăng đều 0 → 2 → 4 → ... dù request rơi vào container nào. Nếu lưu trong dict, mỗi container có RAM riêng nên con số nhảy lung tung (ví dụ 0, 0, 2, 0, 2, 4...) tùy nginx round-robin vào đâu, và về 0 khi container restart.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Lỗi: `docker compose up` báo `request returned 500 Internal Server Error for API route ... dockerDesktopLinuxEngine/_ping`. Tìm nguyên nhân: `docker version` chỉ có phần Client, không có Server → mở Docker Desktop thấy "Virtualization support not detected", Task Manager báo Virtualization: Disabled. Sửa: bật Intel VT-x/AMD SVM trong BIOS, bật `VirtualMachinePlatform` + WSL2, khởi động lại. Với bản cloud thì build chạy trên Render/Railway nên không phụ thuộc Docker ở máy.
