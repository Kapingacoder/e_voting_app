# 🔐 Fully Automated Password Reset Flow (NO ADMIN NEEDED!)

## 📋 Muhtasari

Mfumo huu unafanya **PASSWORD RESET AUTOMATIC 100%** bila admin. Voter anaweza kubadilisha password yake mwenyewe kwa kujibu security question sahihi.

---

## 🚀 Flow Kamili (Step by Step)

### **HATUA 1: Voter Anaomba Password Reset**

**Location**: Mobile App → Login Screen → "Forgot Password"

1. Voter anabofya "Forgot Password"
2. Anaingia admission number yake
3. Anabofya "Send Reset Link"

**Backend Code**:
```dart
ApiService.requestSecurityQuestionForForgotPassword(admissionNumber)
```

**System Actions**:
- ✅ Kutafuta voter kwenye database
- ✅ Ku-verify ameandika security question
- ✅ Kutengeneza encoded link yenye: username, question, email, timestamp
- ✅ Kutuma email na reset link

**Email Example**:
```
Habari John Mwangi,

Umetuma ombi la kubadili password yako.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HATUA ZA KUBADILI PASSWORD:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Bofya link hii chini:
   https://YOUR_GITHUB.github.io/e_voting_app/#/reset-password?data=eyJ...

2. Utaona swali la usalama uliloweka

3. Jibu swali kwa usahihi

4. Password mpya itatumwa kwa email yako

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

KAMBA LA MUHIMU:
- Link hii inafanya kazi kwa saa 1 tu
- Kama hukuomba password reset, puuza email hii
- Usishirikiane link hii na mtu yeyote

Asante,
E-Voting System Team
```

---

### **HATUA 2: Voter Anabofya Reset Link**

**What Happens**:
1. Link inafungua browser automatically
2. Web page inaload: `reset_password_page.dart`
3. System inadecode data kutoka URL:
   - Username/Admission Number
   - Security Question
   - Voter Email
   - Voter Name
   - Timestamp (ku-verify link bado ni valid)

**Code**:
```dart
// Decode URL data
final decoded = utf8.decode(base64Url.decode(data));
final decodedData = jsonDecode(decoded);

// Verify timestamp (1 hour expiry)
final timestamp = decodedData['timestamp'];
final now = DateTime.now().millisecondsSinceEpoch;
if (now - timestamp > 3600000) {  // 1 hour in milliseconds
  return 'Link expired';
}

// Extract data
_admissionNumber = decodedData['admission'];
_securityQuestion = decodedData['question'];
_voterEmail = decodedData['email'];
_voterName = decodedData['name'];
```

**UI Display**:
- 🔐 Lock icon
- Welcome message: "Welcome, John Mwangi"
- Security Question displayed in blue box
- Answer input field
- CAPTCHA (math problem)
- "I'm not a robot" checkbox
- Submit button

---

### **HATUA 3: Voter Anajibu Security Question**

**User Actions**:
1. ✏️ Anaandika jibu la security question
2. ☑️ Anabofya "I'm not a robot" checkbox
3. 🔢 Anajibu math CAPTCHA (e.g., 5 + 3 = ?)
4. 🚀 Anabofya "Reset Password" button

**Validations**:
```dart
// Validate form
if (!_formKey.currentState!.validate()) return;

// Validate checkbox
if (!_isNotRobot) {
  error = 'Tafadhali thibitisha kwamba wewe si robot.';
  return;
}

// Validate CAPTCHA
final captchaAnswer = int.tryParse(_captchaController.text.trim());
if (captchaAnswer != _correctAnswer) {
  error = 'Jibu la hesabu si sahihi. Jaribu tena.';
  _regenerateCaptcha();  // Generate new question
  return;
}
```

---

### **HATUA 4: Automatic Verification (NO ADMIN!)**

**Backend Call**:
```dart
final result = await ApiService.resetPasswordWithSecurityAnswer(
  _admissionNumber!,    // e.g., "1001" or "john_doe"
  _answerController.text.trim(),  // e.g., "Nairobi"
);
```

**What Happens in Backend** (`api_service.dart`):

1. **Find Voter**:
```dart
final normalizedInput = _normalizeAdmission(usernameOrAdmission);

for (final voter in voters) {
  final voterUsername = _normalizeAdmission(voter['username']);
  final voterAdmission = _normalizeAdmission(voter['admissionNumber']);
  
  if (voterUsername == normalizedInput || voterAdmission == normalizedInput) {
    // Found voter!
  }
}
```

2. **Verify Answer** (Case-insensitive, trimmed):
```dart
// Normalize both answers (trim + lowercase)
final providedHash = _hashText(answer.trim().toLowerCase());
final storedHash = voter['securityAnswerHash'];

if (providedHash == storedHash) {
  // ✅ MATCH! Answer is correct
}
```

3. **Generate New Password**:
```dart
final fullName = matchedVoter['fullName'];  // "John Mwangi"
final newPassword = _defaultPasswordFor(fullName);  // "John123"
```

4. **Update Database**:
```dart
final updated = voters.map((voter) {
  if (voter['id'] == matchedVoter['id']) {
    return {
      ...voter,
      'password': newPassword,
      'passwordHash': _hashText(newPassword),
      'isFirstLogin': false,
      'forcePasswordChange': false,
    };
  }
  return voter;
}).toList();

await _setVoters(updated);
```

5. **Send Email with New Password**:
```dart
final email = matchedVoter['email'];
final subject = 'Password Yako Mpya - E-Voting System';
final body = '''
Habari ${matchedVoter['fullName']},

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UMEFANIKIWA KUBADILI PASSWORD!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Umejibu swali la usalama kwa usahihi.

Hii ndiyo credentials zako mpya za kuingia:

Username: ${matchedVoter['username']}
Password: $newPassword

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tafadhali:
1. Ingia kwa kutumia password hii mpya
2. Kumbuka kuhifadhi password yako kwa usalama

Kama hukuomba kubadili password, wasiliana na admin MARA MOJA.

Asante,
E-Voting System Team
''';

await _trySendEmail(email, subject, body);
```

---

### **HATUA 5: Success Message**

**Web Page Display** (`_buildSuccessView()`):

```
✅ Password Reset Successful!

[Email Icon]
Check Your Email

Tumekutumia password mpya kwenye: john@school.edu

[Phone Icon]
Hatua Zinazofuata:

1️⃣ Angalia email yako kupata password mpya
2️⃣ Fungua E-Voting mobile app
3️⃣ Login kwa password mpya uliyopokea

Unaweza kufunga ukurasa huu sasa.
```

---

## 🔒 Security Features

### 1. **Link Expiration (1 Hour)**
```dart
final timestamp = decodedData['timestamp'];
final now = DateTime.now().millisecondsSinceEpoch;
final hourInMs = 60 * 60 * 1000;

if (now - timestamp > hourInMs) {
  return 'This reset link has expired. Please request a new one.';
}
```

### 2. **Answer Hashing (SHA-256)**
```dart
// During setup
final answerHash = _hashText(answer.trim().toLowerCase());
voter['securityAnswerHash'] = answerHash;

// During verification
final providedHash = _hashText(answer.trim().toLowerCase());
if (providedHash == storedHash) {
  // Match!
}
```

### 3. **CAPTCHA (Math Problem)**
```dart
final random = Random();
_num1 = random.nextInt(10) + 1;  // 1-10
_num2 = random.nextInt(10) + 1;  // 1-10
_correctAnswer = _num1 + _num2;

// Display: "5 + 3 = ?"
```

### 4. **"I'm Not a Robot" Checkbox**
```dart
if (!_isNotRobot) {
  error = 'Tafadhali thibitisha kwamba wewe si robot.';
  return;
}
```

### 5. **Case-Insensitive Answer Matching**
```dart
// "NAIROBI", "Nairobi", "nairobi" → all match!
final normalizedAnswer = answer.trim().toLowerCase();
```

### 6. **Username/Admission Normalization**
```dart
// "1001", " 1001 ", "1001" → all match "1001"
final normalized = value.toString().trim();
```

---

## 📊 Database Records

### **Forgot Password Email Record**
```dart
{
  'id': 1234567890,
  'email': 'john@school.edu',
  'username': '1001',
  'name': 'John Mwangi',
  'type': 'security_question',
  'question': 'What is your mother\'s name?',
  'resetLink': 'https://...',
  'subject': 'Password Recovery - Reset Your Password',
  'body': '...',
  'sentAt': '2025-01-15T10:30:00.000Z',
  'sent': true,
  'error': null
}
```

### **Password Reset Success Record**
```dart
{
  'id': 1234567891,
  'email': 'john@school.edu',
  'username': '1001',
  'name': 'John Mwangi',
  'newPassword': 'John123',
  'type': 'password_reset_success',
  'subject': 'Password Yako Mpya - E-Voting System',
  'body': '...',
  'sentAt': '2025-01-15T10:35:00.000Z',
  'sent': true
}
```

---

## 🧪 Test Scenarios

### ✅ **Test 1: Successful Reset**
1. Voter: admission "1001", answer "Nairobi"
2. Anaomba reset → Email sent
3. Anabofya link → Page loads
4. Anajibu "nairobi" (lowercase) → ✅ Match!
5. New password: "John123"
6. Email sent → ✅ Success!

### ❌ **Test 2: Wrong Answer**
1. Voter anajibu "Mombasa" (wrong)
2. System: ❌ "Jibu la swali la usalama si sahihi"
3. CAPTCHA regenerates
4. Voter anajaribu tena

### ⏰ **Test 3: Expired Link**
1. Link created at 10:00 AM
2. Voter anabofya link at 11:30 AM (1.5 hours later)
3. System: ❌ "This reset link has expired"

### 🤖 **Test 4: Failed CAPTCHA**
1. CAPTCHA: "5 + 3 = ?"
2. Voter anaandika "7" (wrong)
3. System: ❌ "Jibu la hesabu si sahihi"
4. New CAPTCHA generated

---

## 🎯 Key Benefits

| Feature | Benefit |
|---------|---------|
| **No Admin Involvement** | Voter anaweza ku-reset password any time, 24/7 |
| **Secure** | SHA-256 hashing, link expiration, CAPTCHA |
| **Fast** | Automated process - takes < 2 minutes |
| **User-Friendly** | Clear instructions, good UI/UX |
| **Email Confirmation** | Voter anapokea password via email |
| **Audit Trail** | All reset attempts saved in database |

---

## 🛠️ Configuration Required

### **SMTP Settings** (Admin Dashboard → SMTP Config)
```
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: your-app-password
From: noreply@votingapp.com
SSL: No (use TLS)
```

### **GitHub Pages URL** (Update in `api_service.dart`)
```dart
final resetLink = kIsWeb 
    ? '${Uri.base.origin}/#/reset-password?data=$encodedData'
    : 'https://YOUR_GITHUB_USERNAME.github.io/e_voting_app/#/reset-password?data=$encodedData';
```

**Replace**: `YOUR_GITHUB_USERNAME` with your actual GitHub username

---

## 📝 Summary

**MFUMO NI FULLY AUTOMATED! 🎉**

- ✅ Voter anaomba reset → Email sent
- ✅ Voter anabofya link → Page loads
- ✅ Voter anajibu question → Verified automatically
- ✅ Password mpya → Generated & emailed
- ✅ Voter anaingia → With new password

**HAKUNA ADMIN INVOLVEMENT! 🚀**

---

## 🐛 Troubleshooting

### Issue 1: "Email haikuweza kutumwa"
**Cause**: SMTP settings hazijawekwa
**Solution**: Weka SMTP config kwenye Admin Dashboard

### Issue 2: "Jibu la swali la usalama si sahihi" (lakini jibu ni sahihi!)
**Cause**: Answer ilihifadhiwa na spaces au capitalization tofauti
**Solution**: System sasa ina-normalize (trim + lowercase) automatically

### Issue 3: "Link expired"
**Cause**: Zaidi ya saa 1 imepita
**Solution**: Omba reset link mpya

### Issue 4: Web page haiload
**Cause**: Data kwenye URL ni corrupted au invalid
**Solution**: Omba reset link mpya

---

**🎊 CONGRATULATIONS! Password reset sasa inafanya kazi 100% automatic bila admin! 🎊**
