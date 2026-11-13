# Skill_Workflow_A.I

Bộ skill và quy chuẩn vận hành A.I Coding Agent dùng chung cho mọi dự án mới hoặc dự án cũ.

Repo này kết hợp hai bộ skill chuẩn MIT cùng quy tắc quản lý ngữ cảnh, code sạch và Git/GitHub:

1. **Khung xương chính (`obra/superpowers` — Tự động cho mọi tác vụ):**
   - Khởi động với `using-superpowers`, `brainstorming`, `writing-plans`.
   - Chia nhỏ yêu cầu thành các task độc lập, mở subagent sạch ngữ cảnh cho từng task (`subagent-driven-development`, `dispatching-parallel-agents`).
   - Tuân thủ TDD nghiêm ngặt (`test-driven-development`) và kiểm chứng đầu ra thực tế (`verification-before-completion`) trước khi báo hoàn thành.
2. **Công cụ gọi tay (`mattpocock/skills` — Chỉ chạy khi bạn chat lệnh kích hoạt):**
   - Đã khóa/khoanh vùng các skill trùng vai trò (`tdd`, `code-review`, `diagnosing-bugs`, `pr`, v.v.) để không đè luồng tự động của `superpowers`.
   - Chat **`quy trinh moi`** *(thay cho `/grill-with-docs` — Dùng lúc mới khởi tạo dự án hoặc thêm tính năng lớn)*:
     - **Cơ chế:** Khi bạn chat `"quy trinh moi"`, AI sẽ đóng vai người thẩm định, hỏi vặn lại bạn từng câu một về logic nghiệp vụ, dữ liệu đầu vào/ra cho đến khi không còn điểm mờ nào, sau đó tự chốt lại thành tài liệu chuẩn trong `GLOSSARY.md` và `docs/adr/`.
     - **Lý do phải gọi tay:** Nếu để tự động, mỗi lần bạn nhờ sửa một lỗi nhỏ AI cũng sẽ dừng lại để "phỏng vấn" bạn rất mất thời gian.
   - Chat **`nghi ngoi`** *(thay cho `/handoff` — Dùng ở cuối buổi làm việc hoặc khi chat đã quá dài)*:
     - **Cơ chế:** Khi chuẩn bị tắt IDE nghỉ ngơi hoặc thấy AI bắt đầu phản hồi chậm do lịch sử chat dài, bạn chat `"nghi ngoi"`. AI sẽ tự động tóm tắt toàn bộ việc vừa làm, ghi vào đầu file `PROGRESS.md`, đẩy các mốc cũ hơn 10 mốc sang `ARCHIVE.md` và viết sẵn hướng dẫn cho phiên làm việc ngày hôm sau.
   - Chat **`cau hinh`** *(thay cho `/wizard` — Dùng khi cần cấu hình các thứ bên ngoài code)*:
     - **Cơ chế:** Dành cho các thao tác AI không thể tự bấm thay bạn như tạo file `.env`, lấy API Key, cấu hình GitHub Secrets hoặc cài đặt môi trường. Khi bạn chat `"cau hinh"`, AI sẽ sinh ra một đoạn bash script tương tác chạy trên terminal để dẫn dắt bạn nhập từng thông số cho đến khi hoàn tất.
3. **Quản lý trí nhớ & Tiêu chuẩn Git:**
   - Mở phiên chỉ đọc `GEMINI.md` và `PROGRESS.md` (không tự ý đọc lan man các `.md` khác).
   - Tự kiểm tra và tạo nếu thiếu 4 file gốc: `.gitignore` (chặn `.env`, `.private-journal/`, build/log), `README.md`, `GEMINI.md` (< 300 dòng), `PROGRESS.md`.
   - Xoay vòng `PROGRESS.md` giữ tối đa 10 mốc gần nhất; mốc cũ chuyển sang `ARCHIVE.md`.
   - Code sạch (xóa code/import/file thừa, comment giải thích **WHY**), kiểm thử qua mới `commit`, xong tính năng/fix/cuối phiên mới `push` (rà soát không lộ file nhạy cảm).
4. **3 MCP Server bổ trợ (Cài tự động vào `~/.gemini/config/mcp_config.json`):**
   - **`playwright` (`microsoft/playwright-mcp`):** Điều khiển trình duyệt nhẹ qua cây Accessibility để mở localhost, bấm thử nút, đọc log Console/lỗi render ngay trong bước `verification-before-completion` trước khi `git commit`.
   - **`private-journal` (`obra/superpowers-marketplace` / `private-journal-mcp`):** Sổ tay ngữ nghĩa cục bộ lưu xuyên dự án (môi trường, mẹo debug, bài học kiến trúc) tại `~/.private-journal/`, tránh AI quên kinh nghiệm khi sang repo mới (`.private-journal/` cục bộ được gitignore sẵn).
   - **`context7` (`upstash/context7`):** Tự động kéo docs và ví dụ API mới nhất của thư viện bên thứ ba vào ngữ cảnh kèm quy tắc cứng trong `GEMINI.md`: *"Luôn gọi Context7 để tra cứu API trước khi viết code tích hợp thư viện ngoài"*.

---

## Prompt 1 câu để tích hợp vào dự án mới hoặc dự án cũ

Copy nguyên văn đoạn dưới đây gửi cho A.I ngay lần chat đầu tiên trong dự án bất kỳ:

```text
Hãy đọc hướng dẫn tại https://github.com/adwewecat/Skill_Workflow_A.I.git (file INSTALL.md), tích hợp toàn bộ bộ skill (khung xương tự động obra/superpowers + công cụ gọi tay mattpocock/skills kích hoạt theo từ khóa chat "quy trinh moi", "nghi ngoi", "cau hinh"), cấu hình không ghi đè 3 MCP server (playwright, private-journal, context7) vào MCP config toàn cục, và thiết lập/cập nhật không ghi đè 4 file chuẩn (.gitignore có chặn .env và .private-journal/, README.md, GEMINI.md dưới 300 dòng, PROGRESS.md giữ tối đa 10 mốc xoay vòng sang ARCHIVE.md) vào dự án này; sau đó quét nhanh cấu trúc code và manifest để điền thông tin thật vào GEMINI.md (không tự ý đọc lan man các file .md khác), xóa thư mục clone tạm nếu có, và từ giờ tuân thủ nghiêm ngặt quy trình đọc phân tầng (chỉ đọc GEMINI.md + PROGRESS.md khi mở phiên), gọi Context7 tra cứu API trước khi viết code tích hợp thư viện ngoài, TDD, subagent độc lập, verification (gồm Playwright MCP cho giao diện web) trước khi báo hoàn thành và tiêu chuẩn Git trong GEMINI.md.
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
| `templates/` | File mẫu `.gitignore`, `README.md`, `GEMINI.md`, `PROGRESS.md`, `ARCHIVE.md`, `AGENTS.md`, `CLAUDE.md`, `mcp_config.json` |
| `scripts/` | Script cài đặt không ghi đè cho Windows (`install.ps1`) và Unix (`install.sh`), tự gộp MCP server an toàn |
| `INSTALL.md` | Hướng dẫn chuẩn từng bước để A.I tự đọc và tích hợp |
| `mcp_config.json`, `hooks/`, `assets/` | Cấu hình 3 MCP server (`playwright`, `private-journal`, `context7`), hook `using-superpowers` và icon plugin |
| `.antigravity-plugin/`, `.claude-plugin/`, `gemini-extension.json` | Manifest tương thích đa công cụ A.I |
| `licenses/` | Bản quyền MIT gốc của `obra/superpowers` và `mattpocock/skills` |
