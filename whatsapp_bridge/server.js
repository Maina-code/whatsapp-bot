const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

require('dotenv').config();

const WHATSAPP_API_URL = process.env.WHATSAPP_API_URL;
const ACCESS_TOKEN = process.env.ACCESS_TOKEN;

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

//endpoint to send messages from WhatsApp
app.post('/send-message', async (req, res) => {
  const { phoneNumber, message } = req.body;

  try {
    const response = await axios.post(
      WHATSAPP_API_URL,
      {
        messaging_product: 'whatsapp',
        to: phoneNumber,
        text: { body: message }
      },
      {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${ACCESS_TOKEN}`
        }
      }
    );

    res.status(200).json({ success: true, data: response.data });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

//endpoint to receive messages from WhatsApp
app.post('/webhook', (req, res) => {
  const data = req.body;

  console.log('Webhook received:', data);

  // Handle the incoming message here

  res.sendStatus(200);
});

// Endpoint to verify the webhook
app.get('/webhook', (req, res) => {
  const VERIFY_TOKEN = 'your-verify-token';

  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode && token === VERIFY_TOKEN) {
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});
