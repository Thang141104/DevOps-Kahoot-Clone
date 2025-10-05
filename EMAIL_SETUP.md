# Email Configuration Guide

## Setup Gmail for Sending OTP Emails

### Step 1: Enable 2-Factor Authentication
1. Go to your Google Account: https://myaccount.google.com/
2. Select **Security** from the left menu
3. Under "Signing in to Google", select **2-Step Verification**
4. Follow the steps to enable it

### Step 2: Generate App Password
1. Go to: https://myaccount.google.com/apppasswords
2. Select app: **Mail**
3. Select device: **Other (Custom name)**
4. Type: **Quiz App**
5. Click **Generate**
6. Copy the 16-character password

### Step 3: Update .env File
Open `services/auth-service/.env` and update:

```env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=xxxx xxxx xxxx xxxx  # The 16-character app password
```

### Alternative: Use Other Email Services

#### Outlook/Hotmail
```env
EMAIL_HOST=smtp-mail.outlook.com
EMAIL_PORT=587
EMAIL_USER=your-email@outlook.com
EMAIL_PASSWORD=your-password
```

#### Yahoo Mail
```env
EMAIL_HOST=smtp.mail.yahoo.com
EMAIL_PORT=587
EMAIL_USER=your-email@yahoo.com
EMAIL_PASSWORD=your-app-password
```

#### SendGrid (Professional)
```env
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USER=apikey
EMAIL_PASSWORD=your-sendgrid-api-key
```

### Testing Email Configuration

Start the Auth Service and register a test user:
```powershell
cd services\auth-service
npm run dev
```

Then use Postman or register through the frontend to test email sending.

### Troubleshooting

**Error: "Invalid login"**
- Make sure you're using the App Password, not your regular Gmail password
- Check that 2FA is enabled

**Error: "Connection timeout"**
- Check your firewall/antivirus settings
- Try port 465 with `secure: true`

**Emails not received**
- Check spam folder
- Verify email address is correct
- Check Gmail sent items to confirm email was sent

### Development Mode (No Email)

For development without email, you can temporarily log the OTP to console:

In `routes/auth.routes.js`, add after generating OTP:
```javascript
console.log('🔐 OTP for', email, ':', otp);
```

This will print the OTP in the terminal for testing.
