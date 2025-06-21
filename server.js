const express = require("express");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");
const fs = require("fs");
const twilio = require("twilio");
require("dotenv").config();

const app = express();
const port = process.env.PORT || 3000;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

console.log("🔑 OpenAI Key:", OPENAI_API_KEY ? "Loaded ✅" : "Missing ❌");

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.post("/message", async (req, res) => {
  const incomingMsg = req.body.Body;
  const sender = req.body.From;

  console.log(`📩 Received: ${incomingMsg} from ${sender}`);

  // Log to file
  const logLine = `${new Date().toISOString()} - ${sender}: ${incomingMsg}\n`;
  fs.appendFileSync("messages.log", logLine);

  let aiReply = "Sorry, something went wrong.";

  // Prepare AI request with timeout
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000); // 30 sec

  try {
    const aiResponse = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "HTTP-Referer": "https://openrouter.ai", // Required by OpenRouter
        "X-Title": "whatsapp-bot"
      },
      body: JSON.stringify({
        model: "openai/gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are a helpful assistant for WhatsApp support." },
          { role: "user", content: incomingMsg }
        ]
      }),
      signal: controller.signal
    });

    clearTimeout(timeout);

    const data = await aiResponse.json();
    console.log("🤖 OpenRouter raw:", data);
    aiReply = data.choices?.[0]?.message?.content?.trim() || aiReply;
  } catch (error) {
    clearTimeout(timeout);
    console.error("❌ AI fetch error:", error);
  }

  // Send AI response to WhatsApp
  const twiml = new twilio.twiml.MessagingResponse();
  twiml.message(aiReply);
  res.type("text/xml").send(twiml.toString());
});

app.listen(port, () => {
  console.log(`✅ Server running at http://localhost:${port}`);
});
