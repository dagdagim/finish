import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const getTransporter = () => {
  const user = (process.env.GMAIL_USER || 'developerswork444@gmail.com').trim();
  const pass = (process.env.GMAIL_PASS || 'rdgi zmzx fdbg xalh').replace(/\s+/g, '');

  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user,
      pass
    }
  });
};

export const sendOtpEmail = async (
  toEmail: string,
  otpCode: string,
  purpose: string = 'Google Sign-In'
): Promise<{ success: boolean; messageId?: string; error?: string }> => {
  try {
    const transporter = getTransporter();
    const sender = process.env.GMAIL_USER || 'developerswork444@gmail.com';

    const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>FINISH Verification Code</title>
      <style>
        body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px; color: #1E293B; }
        .card { max-width: 500px; margin: 0 auto; background: #FFFFFF; border-radius: 18px; border: 1px solid #E2E8F0; padding: 36px 28px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.06); text-align: center; }
        .brand-badge { display: inline-flex; align-items: center; gap: 8px; background: #ECFDF5; border: 1px solid #A7F3D0; border-radius: 999px; padding: 6px 16px; margin-bottom: 20px; }
        .brand-text { font-size: 15px; font-weight: 800; color: #059669; letter-spacing: 1.5px; }
        h1 { font-size: 24px; font-weight: 800; color: #0F172A; margin: 0 0 10px 0; }
        p.subtitle { font-size: 14px; color: #64748B; margin: 0 0 24px 0; line-height: 1.5; }
        .otp-container { margin: 24px 0; }
        .otp-box { font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #047857; background: #F0FDF4; border: 2px dashed #10B981; border-radius: 14px; padding: 16px 28px; display: inline-block; font-family: 'Courier New', monospace; }
        .expiry-note { font-size: 12px; color: #94A3B8; margin-top: 14px; }
        .divider { height: 1px; background: #E2E8F0; margin: 28px 0; }
        .security-tip { font-size: 12px; color: #64748B; line-height: 1.6; text-align: left; background: #F8FAFC; padding: 14px 16px; border-radius: 10px; border-left: 3px solid #10B981; }
        .footer { font-size: 11px; color: #94A3B8; margin-top: 24px; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="brand-badge">
          <span class="brand-text">FINISH</span>
        </div>
        <h1>Your Verification Code</h1>
        <p class="subtitle">Use the one-time password (OTP) below to authenticate your account with <strong>${toEmail}</strong> for ${purpose}.</p>
        
        <div class="otp-container">
          <div class="otp-box">${otpCode}</div>
          <div class="expiry-note">⏳ This code expires in <strong>10 minutes</strong>.</div>
        </div>

        <div class="divider"></div>

        <div class="security-tip">
          🛡️ <strong>Security reminder:</strong> Never share this code with anyone. FINISH administrators and agents will never ask for your verification code.
        </div>

        <div class="footer">
          FINISH · Micro-task Marketplace · Addis Ababa, Ethiopia<br>
          Small jobs. Real people. Done.
        </div>
      </div>
    </body>
    </html>
    `;

    const mailOptions = {
      from: `"FINISH Security" <${sender}>`,
      to: toEmail,
      subject: `${otpCode} is your FINISH verification code`,
      text: `Your FINISH verification code is: ${otpCode}. Valid for 10 minutes. Do not share this code.`,
      html: htmlContent
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`[EmailService] OTP sent successfully to ${toEmail}. MessageId: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error: any) {
    console.error(`[EmailService] Failed to send OTP to ${toEmail}:`, error.message || error);
    return { success: false, error: error.message || 'Failed to send email' };
  }
};
