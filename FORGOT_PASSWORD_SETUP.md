# E-Voting App - Forgot Password Email System

## Mfumo wa Kubadili Password Kupitia Email

### Jinsi Unavyofanya Kazi:

1. **Voter Anasahau Password:**
   - Voter anabofya "Umesahau Password?" kwenye login screen
   - Anaandika admission number yake
   - System inatuma email yenye security question kwenye email yake

2. **Email ya Security Question:**
   - Voter anapokea email yenye security question aliyeweka wakati wa kuandikisha
   - Email inamuambia ajibu kwa ku-reply email hiyo au kuwasiliana na admin

3. **Admin Anasaidia:**
   - Admin anaingia kwenye "Password Reset Requests" dashboard
   - Anaona orodha ya wote waliotuma maombi
   - Anaangalia email yenye security question
   - Anauliza voter jibu la security question (kwa simu, WhatsApp, nk)
   - Anaandika jibu kwenye system

4. **Password Mpya Inatumwa:**
   - Kama jibu ni sahihi, system inatengeneza password mpya automatically
   - Password mpya inatumwa kwa email ya voter
   - Voter anaweza kuingia kwa password mpya

---

## SMTP Configuration (Gmail)

### Hatua za Kuweka Gmail SMTP:

#### 1. Tengeneza Google App Password

**MUHIMU:** Usitumie password yako ya kawaida ya Gmail! Lazima utengeneze "App Password" maalum.

**Hatua:**

a. Nenda kwenye Google Account yako: https://myaccount.google.com/

b. Ingia kwenye **Security** > **2-Step Verification** (Lazima iwe ON)

c. Scroll down, bofya **App passwords**

d. Chagua:
   - App: **Mail**
   - Device: **Other (Custom name)** - andika "E-Voting App"

e. Bofya **Generate**

f. Nakili password ya digits 16 iliyotokea (mfano: `bcsasatfhwekzosa`)

---

#### 2. Weka SMTP Settings kwenye Admin Dashboard

**Hatua:**

1. Ingia kama **Admin**
2. Nenda kwenye **Profile** (top right icon)
3. Bofya **SMTP Settings**
4. Jaza taarifa:

```
SMTP Host: smtp.gmail.com
Port: 587
Username: gisbertkapinga003@gmail.com (Gmail yako)
From address: gisbertkapinga003@gmail.com
Password: bcsasatfhwekzosa (App Password uliyotengeneza)
Use SSL: OFF (tumia TLS port 587)
```

5. Bofya **"Use Default Gmail SMTP"** kwa kuweka automatic
6. Bofya **Save SMTP Settings**

---

#### 3. Test Kama Inafanya Kazi

**Njia 1: Tuma Credentials kwa Wote**
1. Nenda **Admin Dashboard** > **Wapiga Kura**
2. Bofya icon ya envelope (top right)
3. Confirm kutuma credentials
4. Angalia kama email zinafikika

**Njia 2: Test Password Reset**
1. Toka kwenye admin account
2. Kwenye login screen, bofya **"Umesahau Password?"**
3. Andika admission number ya voter yeyote
4. Angalia email ya voter kama imepokea security question

---

## Credentials za SMTP

**Production Credentials (Gmail Account):**

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=gisbertkapinga003@gmail.com
SMTP_PASSWORD=bcsasatfhwekzosa
SMTP_FROM=gisbertkapinga003@gmail.com
USE_SSL=false
```

**Kumbuka:**
- Password hii (`bcsasatfhwekzosa`) ni **App Password**, sio password ya kawaida
- Hii credentials tayari ziko kwenye code kwa default
- Ukitaka kubadilisha, fanya hivyo kwenye Admin > Profile > SMTP Settings

---

## Troubleshooting

### Email Haijatumwa?

**1. Angalia SMTP Settings:**
- Ingia Admin > Profile > SMTP Settings
- Hakikisha username, password, na host ni sahihi
- Port lazima iwe 587 (TLS) au 465 (SSL)

**2. Gmail Security:**
- Hakikisha 2-Step Verification iko ON kwenye Google Account
- Tumia App Password, sio password ya kawaida
- Angalia https://myaccount.google.com/security

**3. Less Secure Apps:**
- Gmail haitumia "Less Secure Apps" tena
- Lazima utumie App Passwords

**4. Check Logs:**
- Kwenye Admin > Password Reset Requests, angalia kama email iko marked "Failed to Send"
- Bofya email kuona error message

---

## Usalama (Security)

1. **App Password iko wapi?**
   - Hifadhiwa kwenye Flutter Secure Storage (encrypted)
   - Haitokei kwenye logs

2. **Security Question Answer:**
   - Hifadhiwa kama SHA-256 hash
   - Haiwezi kusomwa, inafanana tu

3. **Password Reset:**
   - Lazima mtu ajue security question answer
   - Password mpya inatengenezwa automatically
   - Voter anapokea kwa email yake tu

---

## Maswali Yanayoulizwa Mara Kwa Mara (FAQ)

**Q: Voter hana email, anaweza kubadili password?**
A: Hapana. Lazima voter awe na email kwenye system. Admin anaweza kuongeza email kwenye voter profile.

**Q: Voter amesahau security question answer?**
A: Admin anaweza kusaidia kwa kuzungumza na voter moja kwa moja na kuweka jibu kwenye system.

**Q: Email inafika kwenye Spam?**
A: Ambia voters waangalie folder ya Spam/Junk. Baadaye unaweza ku-configure SPF/DKIM records kwa domain yako.

**Q: Nataka kutumia SMTP server nyingine (sio Gmail)?**
A: Unaweza! Nenda Admin > Profile > SMTP Settings na ubadilishe host, port, username, na password.

---

## Support

Kama una maswali au tatizo:
1. Angalia **Admin Dashboard > Password Reset Requests** kuona history ya emails
2. Angalia **Admin Dashboard > Wapiga Kura** kwa voter details
3. Test SMTP settings kwa kutuma credentials kwanza

---

**Imeandikwa na:** E-Voting Development Team  
**Tarehe:** 2025
