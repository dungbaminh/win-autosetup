# win-autosetup
Windows Auto-Setup
Script tự động hóa toàn diện quá trình thiết lập máy tính chạy Windows 10/11. Chỉ với một dòng lệnh duy nhất, hệ thống của bạn sẽ được kích hoạt, cập nhật, cài đặt Driver và đầy đủ các phần mềm cơ bản mà không cần tương tác thủ công.

🌟 Tính năng nổi bật
Zero-Touch: Chạy một lần và để script tự thực hiện (Tự động Reboot & Resume).

Active First: Kích hoạt Windows bản quyền qua MAS trước để ưu tiên nhận cập nhật.

Update & Driver: Tự động quét Vendor ID (Intel/AMD/NVIDIA) để cài đúng Driver Chipset và GPU (Adrenalin/Game Ready).

Office 2024 Slim: Cài đặt bản Office 2024 mới nhất chỉ với Word, Excel, PowerPoint, OneDrive và tự động kích hoạt.

Essential Apps: Tự động cài Chrome, Zalo, Unikey, WinRAR, 7-Zip, Visual C++.

Windows 11 Tweaks: Đưa Menu chuột phải về phong cách Windows 10 (Classic Context Menu).

System Optimization: Tối ưu RAM ảo (Paging File) và hiệu ứng hình ảnh để máy mượt hơn.

🛠 Cách sử dụng
Chuột phải vào nút Start, chọn Terminal (Admin) hoặc PowerShell (Admin).

Copy và dán dòng lệnh bên dưới rồi nhấn Enter:
PowerShell

irm https://raw.githubusercontent.com/dungbaminh/win_autosetup/main/setup.ps1 | iex

🔄 Quy trình thực hiện (4 Giai đoạn)
Script sẽ tự động khởi động lại máy sau mỗi giai đoạn để đảm bảo tính ổn định:

Stage 1: Kích hoạt Windows (MAS HWID).

Stage 2: Chạy Windows Update toàn diện.

Stage 3: Nhận diện phần cứng và cài đặt Driver (Chipset/GPU).

Stage 4: Cài Office 2024, Zalo, các App cơ bản và tinh chỉnh hệ thống.

⚠️ Lưu ý quan trọng
Internet: Đảm bảo máy tính luôn có kết nối mạng ổn định trong suốt quá trình chạy.

Reboot: Máy sẽ tự khởi động lại khoảng 4 lần. Sau khi đăng nhập vào Desktop, cửa sổ script sẽ tự hiện lên để chạy tiếp (đừng tắt nó đi).

Quyền hạn: Luôn chạy PowerShell với quyền Administrator.

Phát triển bởi dungbaminh
