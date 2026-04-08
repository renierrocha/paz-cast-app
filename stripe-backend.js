const express = require('express');
const Stripe = require('stripe');
const cors = require('cors');

const stripe = Stripe('sk_test_SUA_SECRET_KEY_AQUI'); // Substitua pela sua chave secreta do Stripe
const app = express();
app.use(cors());
app.use(express.json());

app.post('/api/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency, description } = req.body;
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      description,
      payment_method_types: ['card'],
    });
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 4242;
app.listen(PORT, () => console.log(`Stripe backend rodando na porta ${PORT}`));
