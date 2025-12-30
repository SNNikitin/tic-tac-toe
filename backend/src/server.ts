import express from "express";
import cors from "cors";
import nodemailer from "nodemailer";
import dotenv from "dotenv";

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

app.post("/api/games", async (req, res) => {
  const { email, playerName, won, difficulty } = req.body;

  if (!email || !/\S+@\S+\.\S+/.test(email)) {
    return res.status(400).send("Invalid email");
  }

  const id = Date.now().toString();
  let emailSent = false;

  try {
    await transporter.sendMail({
      from: "tic-tac-toe@snnikitin.work",
      to: email,
      subject: `Tic-Tac-Toe: ${won ? "Win" : "Loss"}`,
      text: `Hi ${playerName}!\n\nYou ${won ? "won" : "lost"} on ${difficulty} difficulty.`,
    });

    emailSent = true;
    console.log(`Email sent: ${email}`);
  } catch (err) {
    console.error("Email failed:", err);
  }

  res.send({ id, timestamp: new Date().toISOString(), emailSent });
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Server is running");
});
