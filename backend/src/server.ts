import express from 'express';
import cors from 'cors';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const { 
  EMAIL_HOST: host, 
  EMAIL_PORT: _port, 
  EMAIL_USER: user, 
  EMAIL_PASS: pass 
} = process.env;

const port = Number(_port);
const secure = true;
const auth = { user, pass };

const app = express();

app.use(cors());
app.use(express.json());

const transporter = nodemailer.createTransport({
  host,
  port,
  secure,
  auth,
});

app.post('/api/games', async (request, response) => {
  const { email, playerName, won, difficulty, duration, playedAt, streak } = request.body;

  if (!email || !/\S+@\S+\.\S+/.test(email)) {
    return response.status(400).send('Invalid email');
  }

  const id = Date.now().toString();
  let emailSent = false;

  const durationStr = duration !== undefined && duration !== null ? `${Math.round(duration / 1000)}s` : '';
  const streakStr = streak ? `Current streak: ${streak} wins` : '';
  const parsedDate = playedAt ? new Date(playedAt) : null;
  const date = parsedDate && !isNaN(parsedDate.getTime()) ? parsedDate : new Date();
  const dateStr = date.toLocaleString('en-US', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });

  try {
    await transporter.sendMail({
      from: user || 'tic-tac-toe@snnikitin.work',
      to: email,
      subject: `Tic-Tac-Toe: ${won ? 'Win' : 'Loss'}`,
      text: `Hi ${playerName}!\n\nYou ${
        won ? 'won' : 'lost'
      } on ${difficulty} difficulty.\nDuration: ${durationStr}\nDate: ${dateStr}\n${streakStr}`,
    });

    emailSent = true;
    console.log(`Email sent: ${email}`);
  } catch (err) {
    console.error('Email failed:', err);
  }

  response.send({ id, timestamp: new Date().toISOString(), emailSent });
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Server is running');
});
