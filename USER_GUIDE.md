# User Guide - Authentication Flow

## 📝 Đăng Ký Tài Khoản (Register)

### Bước 1: Truy cập trang đăng ký
1. Mở ứng dụng tại http://localhost:3000
2. Click vào nút **"Create Quiz"**
3. Bạn sẽ được chuyển đến trang **Login**
4. Click vào **"Sign Up"** để đăng ký

### Bước 2: Điền thông tin đăng ký
- **Username**: Tên người dùng (tối thiểu 3 ký tự)
- **Email**: Địa chỉ email hợp lệ
- **Password**: Mật khẩu (tối thiểu 6 ký tự)
- **Confirm Password**: Nhập lại mật khẩu

### Bước 3: Xác nhận OTP
1. Sau khi đăng ký, hệ thống sẽ gửi mã OTP (6 số) đến email
2. Check email (có thể trong spam folder)
3. Nhập 6 số OTP vào ô xác nhận
4. Click **"Verify Email"** hoặc OTP sẽ tự động submit

**Lưu ý:**
- Mã OTP có hiệu lực **10 phút**
- Nếu không nhận được email, click **"Resend Code"** (sau 60s)
- Email sẽ hiển thị trong console nếu chưa cấu hình email service

### Bước 4: Hoàn tất
- Sau khi xác nhận OTP thành công, bạn sẽ tự động đăng nhập
- Chuyển đến trang **Dashboard** để bắt đầu tạo quiz

---

## 🔐 Đăng Nhập (Login)

### Đăng nhập với tài khoản đã có
1. Truy cập trang Login
2. Nhập **Email hoặc Username**
3. Nhập **Password**
4. Click **"Sign In"**

### Trường hợp đặc biệt:
- **Chưa xác thực email**: Hệ thống sẽ chuyển đến trang OTP verification
- **Sai mật khẩu**: Hiển thị thông báo "Invalid credentials"
- **Email chưa đăng ký**: Hiển thị thông báo "Invalid credentials"

---

## 🎯 Tham Gia Quiz (Join Game)

### Dành cho Player (không cần đăng ký)
1. Mở ứng dụng tại http://localhost:3000
2. Click nút **"Join with PIN"**
3. Nhập **Game PIN** (do host cung cấp)
4. Nhập **Nickname** của bạn
5. Chọn **Avatar** (tùy chọn)
6. Click **"Join Game"**

**Không cần đăng nhập/đăng ký để join game!**

---

## 🎮 Flow Hoàn Chỉnh

### Host (Teacher/Creator)
```
Home 
  → Click "Create Quiz" 
  → Login/Register (nếu chưa đăng nhập)
  → Verify OTP (nếu đăng ký mới)
  → Dashboard 
  → Create/Select Quiz 
  → Start Game 
  → Share PIN với players
  → Control Game
  → View Results
```

### Player (Student)
```
Home 
  → Click "Join with PIN"
  → Enter PIN + Nickname
  → Wait in Lobby
  → Answer Questions
  → View Score & Ranking
  → End Game Results
```

---

## 🔑 Token & Session Management

### Lưu trữ thông tin
Sau khi đăng nhập thành công, hệ thống sẽ lưu:
- **JWT Token** → `localStorage.getItem('token')`
- **User Info** → `localStorage.getItem('user')`

### Check login status
```javascript
const token = localStorage.getItem('token');
const user = JSON.parse(localStorage.getItem('user'));

if (token) {
  // User is logged in
  console.log('Welcome', user.username);
} else {
  // User is not logged in
  navigate('/login');
}
```

### Đăng xuất (Logout)
```javascript
localStorage.removeItem('token');
localStorage.removeItem('user');
navigate('/');
```

---

## 📧 Email Templates

### OTP Verification Email
```
Subject: Verify Your Email - Quiz Application
Content: 
  - Welcome message
  - 6-digit OTP code
  - Expiry warning (10 minutes)
  - Instructions
```

### Welcome Email (After Verification)
```
Subject: Welcome to Quiz Application! 🎉
Content:
  - Welcome message
  - Feature highlights
  - Getting started button
  - Support information
```

---

## 🐛 Troubleshooting

### Không nhận được email OTP
1. Check spam/junk folder
2. Verify email address nhập đúng
3. Check console log (development mode)
4. Click "Resend Code"

### Lỗi "Invalid OTP"
- OTP đã hết hạn (>10 phút)
- OTP nhập sai
- Click "Resend Code" để nhận mã mới

### Lỗi đăng nhập
- Check username/email và password
- Verify email nếu chưa verify
- Clear browser cache và thử lại

### Email service không hoạt động
- Check file `.env` trong `services/auth-service`
- Verify Gmail App Password đúng
- Check firewall/antivirus settings
- Xem hướng dẫn trong `EMAIL_SETUP.md`

---

## 📊 Database Schema

### User Collection
```javascript
{
  _id: ObjectId,
  username: String (unique, 3-30 chars),
  email: String (unique, valid email),
  password: String (hashed with bcrypt),
  isVerified: Boolean (default: false),
  otp: {
    code: String (6 digits),
    expiresAt: Date (10 minutes from creation)
  },
  role: String (enum: ['user', 'admin'], default: 'user'),
  createdAt: Date
}
```

---

## 🔒 Security Features

✅ Password hashing với bcrypt  
✅ JWT authentication  
✅ Email verification với OTP  
✅ OTP expiration (10 minutes)  
✅ Rate limiting on API Gateway  
✅ Input validation  
✅ SQL injection protection (MongoDB)  
✅ XSS protection

---

## 🎨 UI/UX Features

✅ Responsive design  
✅ Smooth animations  
✅ Real-time form validation  
✅ Auto-focus next OTP input  
✅ Copy-paste OTP support  
✅ Countdown timer for resend  
✅ Loading states  
✅ Error messages  
✅ Success notifications
