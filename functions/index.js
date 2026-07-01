const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();
const firestore = admin.firestore();

const gmailTransport = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass,
  },
  requireTLS: true,
  tls: {
    ciphers: 'TLSv1.2',
  },
});

gmailTransport.verify((error, success) => {
  if (error) {
    console.error('Email transport verification failed:', error);
  } else {
    console.log('Email transport is ready');
  }
});

exports.sendPasswordResetByAdmission = functions.https.onCall(async (data, context) => {
  const admissionNumber = (data.admissionNumber || '').toString().trim().toLowerCase();
  const authEmail = (data.authEmail || '').toString().trim().toLowerCase();
  const targetEmail = (data.targetEmail || '').toString().trim().toLowerCase();

  if (!admissionNumber || !authEmail) {
    throw new functions.https.HttpsError('invalid-argument', 'Admission number and auth email are required.');
  }

  let registeredEmail = targetEmail;
  if (!registeredEmail) {
    const voterSnapshot = await firestore.collection('voters').doc(admissionNumber).get();
    registeredEmail = voterSnapshot.data()?.email?.toString().trim().toLowerCase() || authEmail;
  }

  if (!registeredEmail) {
    throw new functions.https.HttpsError('not-found', 'No email configured for this admission number.');
  }

  const auth = admin.auth();
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(authEmail);
  } catch (error) {
    throw new functions.https.HttpsError('not-found', 'Firebase user not found for admission.');
  }

  const resetLink = await auth.generatePasswordResetLink(authEmail, {
    url: `https://e-voting-app-64ab0.firebaseapp.com/login`,
    handleCodeInApp: false,
  });

  const mailOptions = {
    from: `E-Voting App <${functions.config().email.user}>`,
    to: registeredEmail,
    subject: 'E-Voting Password Reset',
    html: `
      <p>Hello,</p>
      <p>We received a request to reset your password for E-Voting.</p>
      <p>Click the button below to reset your password securely:</p>
      <p><a href="${resetLink}" style="display:inline-block;padding:12px 18px;background:#1565C0;color:#fff;border-radius:6px;text-decoration:none;">Reset Password</a></p>
      <p>If you did not request this, you can safely ignore this message.</p>
      <p>Admission number: <strong>${admissionNumber}</strong></p>
      <p>Thank you,<br>E-Voting Support</p>
    `,
  };

  await gmailTransport.sendMail(mailOptions);
  return { success: true, email: registeredEmail };
});
