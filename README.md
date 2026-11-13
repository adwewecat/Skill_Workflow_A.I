# Skill_Workflow_A.I

Bộ skill và quy chuẩn vận hành A.I Coding Agent dùng chung cho mọi dự án mới hoặc dự án cũ.

Repo này kết hợp hai bộ skill chuẩn MIT cùng quy tắc quản lý ngữ cảnh, code sạch và Git/GitHub:

1. **Khung xương chính (`obra/superpowers` — Tự động cho mọi tác vụ):**
   - Khởi động với `using-superpowers`, `brainstorming`, `writing-plans`.
   - Chia nhỏ yêu cầu thành các task độc lập, mở subagent sạch ngữ cảnh cho từng task (`subagent-driven-development`, `dispatching-parallel-agents`).
   - Tuân thủ TDD nghiêm ngặt (`test-driven-development`) và kiểm chứng đầu ra thực tế (`verification-before-completion`) trước khi báo hoàn thành.
2. **Công cụ gọi tay (`mattpocock/skills` — Chỉ chạy khi gọi lệnh hoặc cuối cột mốc):**
   - Đã khóa/khoanh vùng các skill trùng vai trò (`tdd`, `code-review`, `diagnosing-bugs`, `pr`, `wizard`, v.v.) để không đè luồng tự động của `superpowers`.
   - `/grill-with-docs`: phỏng vấn thiết kế và chốt quy tắc/thuật ngữ/kiến trúc vào `GLOSSARY.md` và `docs/adr/`.
   - `/handoff`: đóng gói tài liệu bàn giao cuối phiên cho phiên/agent tiếp theo (kèm xoay vòng `PROGRESS.md`).
   - `/wizard`: tạo bash script tương tác hướng dẫn thao tác tay (`.env`, API key, GitHub secrets, hạ tầng).
3. **Quản lý trí nhớ & Tiêu chuẩn Git:**
   - Mở phiên chỉ đọc `GEMINI.md` và `PROGRESS.md` (không tự ý đọc lan man các `.md` khác).
   - Tự kiểm tra và tạo nếu thiếu 4 file gốc: `.gitignore`, `README.md`, `GEMINI.md` (< 300 dòng), `PROGRESS.md`.
   - Xoay vòng `PROGRESS.md` giữ tối đa 10 mốc gần nhất; mốc cũ chuyển sang `ARCHIVE.md`.
   - Code sạch (xóa code/import/file thừa, comment giải thích **WHY**), kiểm thử qua mới `commit`, xong tính năng/fix/cuối phiên mới `push` (rà soát không lộ file nhạy cảm).

---

## Prompt 1 câu để tích hợp vào dự án mới hoặc dự án cũ

Copy nguyên văn đoạn dưới đây gửi cho A.I ngay lần chat đầu tiên trong dự án bất kỳ:

```text
Hãy đọc hướng dẫn tại https://github.com/adwewecat/Skill_Workflow_A.I.git (file INSTALL.md), tích hợp toàn bộ bộ skill (khung xương tự động obra/superpowers + công cụ gọi tay mattpocock/skills) và thiết lập/cập nhật không ghi đè 4 file chuẩn (.gitignore, README.md, GEMINI.md dưới 300 dòng, PROGRESS.md giữ tối đa 10 mốc xoay vòng sang ARCHIVE.md) vào dự án này; sau đó quét nhanh tech stack và cấu trúc code để điền GEMINI.md, xóa thư mục tạm nếu có, và từ giờ tuân thủ nghiêm ngặt quy trình đọc phân tầng (chỉ đọc GEMINI.md + PROGRESS.md khi mở phiên), TDD, subagent độc lập, verification trước khi kết luận và tiêu chuẩn Git trong GEMINI.md.
```

---

## Cài đặt thủ công (nếu muốn chạy script trực tiếp)

### Cách 1: Cài trực tiếp vào từng dự án (khuyên dùng)

Từ thư mục gốc dự án cần tích hợp:

- **Windows PowerShell:**
  ```powershell
  $tmp = Join-Path $env:TEMP "Skill_Workflow_A.I"
  git clone --depth 1 https://github.com/adwewecat/Skill_Workflow_A.I.git $tmp
  powershell -ExecutionPolicy Bypass -File "$tmp\scripts\install.ps1" .
  Remove-Item -Recurse -Force $tmp
  ```
- **macOS / Linux / Git Bash:**
  ```bash
  tmp="$(mktemp -d)/Skill_Workflow_A.I"
  git clone --depth 1 https://github.com/adwewecat/Skill_Workflow_A.I.git "$tmp"
  bash "$tmp/scripts/install.sh" .
  rm -rf "$(dirname "$tmp")"
  ```

Nếu dùng **Claude Code / Codex / Cursor**, thêm cờ `-Harness all -WithPointers` (PowerShell) hoặc `--harness all --with-pointers` (Bash) để cài thêm `.claude/skills/`, `AGENTS.md` và `CLAUDE.md`.

### Cách 2: Cài như Plugin toàn cục (Antigravity)

```bash
agy plugin install https://github.com/adwewecat/Skill_Workflow_A.I.git
```

---

## Cấu trúc thư mục

| Thư mục / File | Vai trò |
| :--- | :--- |
| `skills/` | 42 skills phẳng (15 từ `obra/superpowers` + 27 từ `mattpocock/skills`) |
| `templates/` | File mẫu `.gitignore`, `README.md`, `GEMINI.md`, `PROGRESS.md`, `ARCHIVE.md`, `AGENTS.md`, `CLAUDE.md` |
| `scripts/` | Script cài đặt không ghi đè cho Windows (`install.ps1`) và Unix (`install.sh`) |
| `INSTALL.md` | Hướng dẫn chuẩn từng bước để A.I tự đọc và tích hợp |
| `hooks/`, `assets/` | Hook khởi động `using-superpowers` và icon plugin |
| `.antigravity-plugin/`, `.claude-plugin/`, `gemini-extension.json` | Manifest tương thích đa công cụ A.I |
| `licenses/` | Bản quyền MIT gốc của `obra/superpowers` và `mattpocock/skills` |
